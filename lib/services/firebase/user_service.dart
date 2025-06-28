import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı verilerini yükle
  static Future<Map<String, dynamic>> loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      String userEmail = user.email ?? 'No email';

      // Firestore'dan kullanıcı bilgilerini çek
      DocumentSnapshot userDoc = await _firestore
          .collection('users_vki_data')
          .doc(user.uid)
          .get();

      String userName = 'No name';
      String userHeight = '';

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['name'] ?? 'No name';
        userHeight = userData['height']?.toString() ?? '';
      }

      return {
        'name': userName,
        'email': userEmail,
        'height': userHeight,
      };
    } catch (e) {
      throw Exception('Error loading user data: $e');
    }
  }

  // Kullanıcı adını güncelle
  static Future<void> updateUserName(String newName) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('users_vki_data').doc(user.uid).update({
        'name': newName,
      });
    } catch (e) {
      throw Exception('Error updating name: $e');
    }
  }

  // Kullanıcı boyunu güncelle
  static Future<void> updateUserHeight(String newHeight) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('users_vki_data').doc(user.uid).update({
        'height': int.parse(newHeight),
      });
    } catch (e) {
      throw Exception('Error updating height: $e');
    }
  }

  // Hesabı sil
  static Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Önce Firestore'dan kullanıcı belgesini sil
      await _firestore.collection('users_vki_data').doc(user.uid).delete();
      
      // Sonra Authentication'dan kullanıcıyı sil
      await user.delete();
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  // Çıkış yap
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }

  // Şu anki kullanıcıyı al
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}