import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserToFirestore(User user) async {
  print("🔥 saveUserToFirestore CALLED");

  try {
    final userRef = _firestore.collection('users').doc(user.uid);

    await userRef.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'role': 'farmer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("✅ User saved to Firestore");
  } catch (e) {
    print("❌ Firestore error: $e");
  }
}



  // Sign Up with Email & Password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Email & Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ CORRECT Sign Out (Firebase + Google)
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // VERY IMPORTANT
    await _auth.signOut();
  }

  // Current User
  User? get currentUser => _auth.currentUser;
  
  

  // Sign In with Google
Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential =
        GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    final User? user = userCredential.user;

    // ✅ THIS IS THE MISSING PART
    if (user != null) {
      await saveUserToFirestore(user);
    }

    return user;
  } catch (e) {
    throw Exception("Google Sign-In failed: $e");
  }
}
}