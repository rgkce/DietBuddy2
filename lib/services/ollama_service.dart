// lib/services/ollama_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  static const String _baseUrl = 'http://127.0.0.1:11434';
  static const String _defaultModel = 'phi3:mini';
  
  // Mevcut modelleri listele
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/tags'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['models'] as List)
            .map((model) => model['name'].toString())
            .toList();
      }
    } catch (e) {
      print('Model listesi alınamadı: $e');
    }
    return [];
  }
  
  // Basit mesaj gönderme
  Future<String> sendMessage(String message, {String? model}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model ?? _defaultModel,
          'prompt': message,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Yanıt alınamadı.';
      } else {
        return 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      return 'Bağlantı hatası: Ollama sunucusunun çalıştığından emin olun.';
    }
  }
  
  // Konuşma geçmişi ile mesaj gönderme
  Future<String> sendMessageWithContext(
    String message, 
    List<Map<String, String>> context,
    {String? model}
  ) async {
    try {
      // Konuşma geçmişini prompt'a ekle
      String fullPrompt = _buildPromptWithContext(message, context);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model ?? _defaultModel,
          'prompt': fullPrompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'max_tokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Yanıt alınamadı.';
      } else {
        return 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      return 'Bağlantı hatası: $e';
    }
  }
  
  // Streaming yanıt (gelişmiş kullanım için)
  Stream<String> sendMessageStream(String message, {String? model}) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/generate'),
      );
      
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': model ?? _defaultModel,
        'prompt': message,
        'stream': true,
      });

      final response = await http.Client().send(request);
      
      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.trim().isNotEmpty) {
              try {
                final data = jsonDecode(line);
                if (data['response'] != null) {
                  yield data['response'];
                }
              } catch (e) {
                // JSON parse hatası, devam et
              }
            }
          }
        }
      }
    } catch (e) {
      yield 'Hata: $e';
    }
  }
  
  String _buildPromptWithContext(String message, List<Map<String, String>> context) {
    String prompt = "Aşağıdaki konuşma geçmişini göz önünde bulundurarak yanıt ver:\n\n";
    
    // Son 5 mesajı al (performans için)
    final recentContext = context.length > 10 
        ? context.sublist(context.length - 10) 
        : context;
    
    for (final msg in recentContext) {
      if (msg['role'] == 'user') {
        prompt += "Kullanıcı: ${msg['message']}\n";
      } else if (msg['role'] == 'bot') {
        prompt += "Asistan: ${msg['message']}\n";
      }
    }
    
    prompt += "\nKullanıcı: $message\nAsistan: ";
    return prompt;
  }
  
  // Sunucu durumunu kontrol et
  Future<bool> isServerRunning() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}