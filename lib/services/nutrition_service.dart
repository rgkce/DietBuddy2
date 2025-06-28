import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionEntry {
  final String id;
  final String name;
  final double gram;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final bool isFromApi;
  final DateTime dateAdded;
  final String userId;

  NutritionEntry({
    required this.id,
    required this.name,
    required this.gram,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    required this.isFromApi,
    required this.dateAdded,
    required this.userId,
  });

  // Firestore'dan veri alma
  factory NutritionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NutritionEntry(
      id: doc.id,
      name: data['name'] ?? '',
      gram: (data['gram'] ?? 0.0).toDouble(),
      calories: data['calories']?.toDouble(),
      protein: data['protein']?.toDouble(),
      carbs: data['carbs']?.toDouble(),
      fat: data['fat']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      isFromApi: data['isFromApi'] ?? false,
      dateAdded: (data['dateAdded'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Firestore'a veri gönderme
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gram': gram,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'isFromApi': isFromApi,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'userId': userId,
    };
  }

  // Gramaj güncellemesi için kopya oluşturma
  NutritionEntry copyWith({
    String? id,
    String? name,
    double? gram,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    bool? isFromApi,
    DateTime? dateAdded,
    String? userId,
  }) {
    return NutritionEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      gram: gram ?? this.gram,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      isFromApi: isFromApi ?? this.isFromApi,
      dateAdded: dateAdded ?? this.dateAdded,
      userId: userId ?? this.userId,
    );
  }
}

class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Koleksiyon referansı
  CollectionReference get _nutritionCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('nutrition');
  }

  // Besin ekleme
  Future<String> addNutrition(NutritionEntry entry) async {
    try {
      final docRef = await _nutritionCollection.add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add nutrition: $e');
    }
  }

  // Besin silme
  Future<void> deleteNutrition(String nutritionId) async {
    try {
      await _nutritionCollection.doc(nutritionId).delete();
    } catch (e) {
      throw Exception('Failed to delete nutrition: $e');
    }
  }

  // Besin gramajını güncelleme
  Future<void> updateNutritionGram(String nutritionId, double newGram) async {
    try {
      // Önce mevcut veriyi al
      final doc = await _nutritionCollection.doc(nutritionId).get();
      final currentEntry = NutritionEntry.fromFirestore(doc);
      
      // Eğer API'den gelen veri ise, besin değerlerini yeni gramaja göre hesapla
      Map<String, dynamic> updateData = {'gram': newGram};
      
      if (currentEntry.isFromApi && currentEntry.calories != null) {
        final originalRatio = currentEntry.gram / 100; // Orijinal API verisi 100g başına
        final newRatio = newGram / 100;
        
        updateData.addAll({
          'calories': (currentEntry.calories! / originalRatio) * newRatio,
          'protein': (currentEntry.protein! / originalRatio) * newRatio,
          'carbs': (currentEntry.carbs! / originalRatio) * newRatio,
          'fat': (currentEntry.fat! / originalRatio) * newRatio,
          'fiber': (currentEntry.fiber! / originalRatio) * newRatio,
        });
      }
      
      await _nutritionCollection.doc(nutritionId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update nutrition: $e');
    }
  }

  // Kullanıcının besinlerini getirme (gerçek zamanlı)
  Stream<List<NutritionEntry>> getUserNutrition() {
    if (_userId == null) return Stream.value([]);
    
    return _nutritionCollection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NutritionEntry.fromFirestore(doc))
            .toList());
  }

  // Bugünkü besinleri getirme
  Stream<List<NutritionEntry>> getTodayNutrition() {
    if (_userId == null) return Stream.value([]);
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return _nutritionCollection
        .where('dateAdded', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateAdded', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NutritionEntry.fromFirestore(doc))
            .toList());
  }

  // Toplam günlük besin değerlerini hesaplama
  Map<String, double> calculateDailyTotals(List<NutritionEntry> entries) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (final entry in entries) {
      if (entry.calories != null) totalCalories += entry.calories!;
      if (entry.protein != null) totalProtein += entry.protein!;
      if (entry.carbs != null) totalCarbs += entry.carbs!;
      if (entry.fat != null) totalFat += entry.fat!;
      if (entry.fiber != null) totalFiber += entry.fiber!;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }
}