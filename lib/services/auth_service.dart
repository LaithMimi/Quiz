import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static Future<User?> signInWithGoogle() async {
    // Step 1 — open the Google account picker
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // User cancelled the picker
    if (googleUser == null) return null;

    // Step 2 — get auth tokens from Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Step 3 — exchange tokens for a Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 4 — sign in to Firebase with that credential
    final UserCredential result =
        await _auth.signInWithCredential(credential);

    return result.user; // returns the signed-in user
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}