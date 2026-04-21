import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
}
