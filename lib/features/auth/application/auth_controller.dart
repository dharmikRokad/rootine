import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../habits/application/habit_providers.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final _googleInitializedProvider = StateProvider<bool>((_) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final googleSignInProvider = Provider<GoogleSignIn>(
  (_) => GoogleSignIn.instance,
);

final ensureSignedInProvider = FutureProvider<void>((ref) async {
  await ref.read(authActionsProvider).ensureSignedIn();
});

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

final signInLoadingProvider = StateProvider<bool>((ref) => false);

final signInErrorProvider = StateProvider<String?>((ref) => null);

class AuthActions {
  AuthActions(this.ref);

  final Ref ref;

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  GoogleSignIn get _googleSignIn => ref.read(googleSignInProvider);

  Future<void> _initializeGoogleIfNeeded() async {
    if (ref.read(_googleInitializedProvider)) {
      return;
    }

    await _googleSignIn.initialize();
    ref.read(_googleInitializedProvider.notifier).state = true;
  }

  Future<void> ensureSignedIn() async {
    return;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _initializeGoogleIfNeeded();

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Failed to obtain ID token from Google Sign-In');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        await current.delete();
      }

      await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _initializeGoogleIfNeeded();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Step 1: Delete the Firebase Auth account first.
    // If this fails (e.g. user cancels re-authentication), we abort before
    // touching any Firestore data, keeping the account fully intact.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Re-authenticate with Google and retry deletion.
        await _initializeGoogleIfNeeded();
        final GoogleSignInAuthentication googleAuth;
        try {
          final googleUser = await _googleSignIn.authenticate();
          googleAuth = googleUser.authentication;
        } catch (_) {
          // User cancelled re-authentication; rethrow so no data is lost.
          rethrow;
        }
        if (googleAuth.idToken == null) {
          // No ID token — cannot re-authenticate; rethrow so no data is lost.
          rethrow;
        }
        final credential = GoogleAuthProvider.credential(
          accessToken: null,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        rethrow;
      }
    }

    // Step 2: Auth account is gone. Now remove Firestore data.
    // If this fails the data becomes orphaned under a UID that no longer has
    // an auth account, so it is permanently inaccessible. The next sign-in
    // with the same Google account creates a new Firebase UID with fresh data.
    final repository = ref.read(habitRepositoryProvider);
    await repository.deleteAllUserData();

    // Step 3: Sign out from Google so the next sign-in starts a fresh session.
    await _initializeGoogleIfNeeded();
    await _googleSignIn.signOut();
  }
}
