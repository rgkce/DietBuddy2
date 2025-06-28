import 'dart:convert';
import 'package:http/http.dart' as http;

class LlamaService {
  final String baseUrl;
  
  LlamaService({required this.baseUrl});
  
  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Üzgünüm, bir yanıt oluşturulamadı.';
      } else {
        throw Exception('API yanıt vermedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('İstek sırasında hata oluştu: $e');
    }
  }
} 