import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeightData {
  final double startWeight;
  final double currentWeight;
  final double goalWeight;
  final int height;
  final int age;

  WeightData({
    required this.startWeight,
    required this.currentWeight,
    required this.goalWeight,
    required this.height,
    required this.age,
  });
}

class FirebaseWeightService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcının mevcut UID'sini alır
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Kullanıcının kilo verilerini yükler
  static Future<WeightData?> loadWeightData() async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        print('Kullanıcı giriş yapmamış');
        return null;
      }

      final doc = await _firestore
          .collection('users_vki_data')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return WeightData(
          startWeight: (data['initialWeight'] ?? data['weight'])?.toDouble() ?? 0.0,
          currentWeight: (data['weight'] as num).toDouble(),
          goalWeight: (data['targetWeight'] as num).toDouble(),
          height: (data['height'] as num).toInt(),
          age: (data['age'] as num).toInt(),
        );
      } else {
        print('Kullanıcı verisi bulunamadı');
        return null;
      }
    } catch (e) {
      print('Firestore veri yükleme hatası: $e');
      return null;
    }
  }

  /// Kullanıcının mevcut kilosunu günceller
  static Future<bool> updateCurrentWeight(double newWeight) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        print('Kullanıcı giriş yapmamış');
        return false;
      }

      await _firestore
          .collection('users_vki_data')
          .doc(uid)
          .update({'weight': newWeight});

      print('Kilo başarıyla güncellendi: $newWeight kg');
      return true;
    } catch (e) {
      print('Kilo güncelleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının tüm verilerini günceller
  static Future<bool> updateUserData({
    double? weight,
    double? targetWeight,
    double? initialWeight,
    int? height,
    int? age,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        print('Kullanıcı giriş yapmamış');
        return false;
      }

      final Map<String, dynamic> updateData = {};
      
      if (weight != null) updateData['weight'] = weight;
      if (targetWeight != null) updateData['targetWeight'] = targetWeight;
      if (initialWeight != null) updateData['initialWeight'] = initialWeight;
      if (height != null) updateData['height'] = height;
      if (age != null) updateData['age'] = age;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users_vki_data')
            .doc(uid)
            .update(updateData);
        
        print('Kullanıcı verisi başarıyla güncellendi');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Veri güncelleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının verilerini real-time olarak dinler
  static Stream<WeightData?> watchWeightData() {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users_vki_data')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return WeightData(
          startWeight: (data['initialWeight'] ?? data['weight'])?.toDouble() ?? 0.0,
          currentWeight: (data['weight'] as num).toDouble(),
          goalWeight: (data['targetWeight'] as num).toDouble(),
          height: (data['height'] as num).toInt(),
          age: (data['age'] as num).toInt(),
        );
      }
      return null;
    });
  }

  /// Kullanıcının giriş durumunu kontrol eder
  static bool get isUserLoggedIn => _auth.currentUser != null;

  /// Kullanıcı çıkış yapar
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Kullanıcı çıkış yaptı');
    } catch (e) {
      print('Çıkış hatası: $e');
    }
  }
}