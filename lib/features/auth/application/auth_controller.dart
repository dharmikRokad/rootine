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
    await _initializeGoogleIfNeeded();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      return;
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
  }

  Future<void> signOut() async {
    await _initializeGoogleIfNeeded();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    // Delete all Firestore data first while the user is still authenticated.
    final repository = ref.read(habitRepositoryProvider);
    await repository.deleteAllUserData();

    final user = _auth.currentUser;
    if (user != null) {
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
            // User cancelled re-authentication; rethrow original error.
            rethrow;
          }
          if (googleAuth.idToken == null) {
            // No ID token returned; cannot re-authenticate.
            rethrow;
          }
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
          await user.delete();
        } else {
          rethrow;
        }
      }
    }

    // Sign out from Google so a fresh sign-in starts a brand-new session.
    await _initializeGoogleIfNeeded();
    await _googleSignIn.signOut();
  }
}
