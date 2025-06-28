import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class FatSecretService {
  static const String _baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  static const String _consumerKey = '344b078119a04ba18fb1bcbdd2f2aa9f'; // Buraya kendi anahtarınızı ekleyin
  static const String _consumerSecret = '045d4428e0544e2bbd5fc5ca5b17bad9'; // Buraya kendi anahtarınızı ekleyin

  // OAuth 1.0 imza oluşturma
  String _generateSignature(Map<String, String> params, String httpMethod) {
    // OAuth parametreleri
    params['oauth_consumer_key'] = _consumerKey;
    params['oauth_nonce'] = DateTime.now().millisecondsSinceEpoch.toString();
    params['oauth_signature_method'] = 'HMAC-SHA1';
    params['oauth_timestamp'] = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    params['oauth_version'] = '1.0';

    // Parametreleri sırala ve birleştir
    var sortedParams = params.keys.toList()..sort();
    var paramString = sortedParams
        .map((key) => '$key=${Uri.encodeComponent(params[key]!)}')
        .join('&');

    // Base string oluştur
    var baseString = '$httpMethod&${Uri.encodeComponent(_baseUrl)}&${Uri.encodeComponent(paramString)}';
    
    // İmza anahtarı
    var signingKey = '${Uri.encodeComponent(_consumerSecret)}&';
    
    // HMAC-SHA1 imzası
    var hmac = Hmac(sha1, utf8.encode(signingKey));
    var digest = hmac.convert(utf8.encode(baseString));
    
    return base64.encode(digest.bytes);
  }

  // API çağrısı
  Future<Map<String, dynamic>> _makeApiCall(Map<String, String> params) async {
    params['format'] = 'json';
    
    var signature = _generateSignature(params, 'POST');
    params['oauth_signature'] = signature;

    var response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('API çağrısı başarısız: ${response.statusCode}');
    }
  }

  // Yemek arama
  Future<List<Food>> searchFoods(String query) async {
    var params = {
      'method': 'foods.search',
      'search_expression': query,
      'max_results': '20',
    };

    try {
      var response = await _makeApiCall(params);
      var foods = <Food>[];
      
      if (response['foods'] != null && response['foods']['food'] != null) {
        var foodList = response['foods']['food'];
        if (foodList is List) {
          foods = foodList.map((food) => Food.fromJson(food)).toList();
        } else {
          foods = [Food.fromJson(foodList)];
        }
      }
      
      return foods;
    } catch (e) {
      print('Yemek arama hatası: $e');
      return [];
    }
  }

  // Yemek detaylarını al
  Future<FoodDetails> getFoodDetails(String foodId) async {
    var params = {
      'method': 'food.get',
      'food_id': foodId,
    };

    try {
      var response = await _makeApiCall(params);
      return FoodDetails.fromJson(response['food']);
    } catch (e) {
      print('Yemek detay hatası: $e');
      throw e;
    }
  }
}

// Food model sınıfı
class Food {
  final String id;
  final String name;
  final String description;
  final String? brandName;

  Food({
    required this.id,
    required this.name,
    required this.description,
    this.brandName,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['food_id'].toString(),
      name: json['food_name'] ?? '',
      description: json['food_description'] ?? '',
      brandName: json['brand_name'],
    );
  }
}

// FoodDetails model sınıfı
class FoodDetails {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String servingDescription;

  FoodDetails({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servingDescription,
  });

  factory FoodDetails.fromJson(Map<String, dynamic> json) {
    var servings = json['servings']['serving'];
    var serving = servings is List ? servings[0] : servings;
    
    return FoodDetails(
      id: json['food_id'].toString(),
      name: json['food_name'] ?? '',
      calories: double.tryParse(serving['calories']?.toString() ?? '0') ?? 0.0,
      protein: double.tryParse(serving['protein']?.toString() ?? '0') ?? 0.0,
      carbs: double.tryParse(serving['carbohydrate']?.toString() ?? '0') ?? 0.0,
      fat: double.tryParse(serving['fat']?.toString() ?? '0') ?? 0.0,
      fiber: double.tryParse(serving['fiber']?.toString() ?? '0') ?? 0.0,
      servingDescription: serving['serving_description'] ?? '100g',
    );
  }
}