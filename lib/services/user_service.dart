import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  //saving the user's email and display name to Firestore
  // so that other users can find them by email when assigning tasks
  static Future<void> saveProfile(User user) async {
    String email = user.email ?? '';
    String displayName = user.displayName ?? '';

    Map<String, dynamic> profileData = {
      'email': email,
      'displayName': displayName,
    };

    //merge: true so we don't overwrite any other fields that might be saved later
    await _db
        .collection('user_profiles')
        .doc(user.uid)
        .set(profileData, SetOptions(merge: true));
  }

  //find a user's UID by their email address
  // it returns null if no account exists with that email
  static Future<String?> findUidByEmail(String email) async {
    QuerySnapshot snap = await _db
        .collection('user_profiles')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return null;
    }

    return snap.docs.first.id;
  }
}
