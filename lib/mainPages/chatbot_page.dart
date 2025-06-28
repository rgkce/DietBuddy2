import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late AnimationController _controllerAnim;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _waveAnimation;

  bool _isTyping = false;
  
  // Ollama konfigürasyonu
  static const String ollamaUrl = 'http://10.0.2.2:11434/api/generate'; // Android emulator için
  // Fiziksel cihaz için bilgisayarınızın IP adresini kullanın: 'http://192.168.1.X:11434/api/generate'
  static const String modelName = 'phi3:mini'; // Önce en küçük modeli deneyin

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controllerAnim, curve: Curves.easeInOut),
    );

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.lineerStart,
          end: AppColors.lineerEnd,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.lineerEnd, end: AppColors.button),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.button, end: AppColors.lineerEnd),
        weight: 1,
      ),
    ]).animate(_controllerAnim);

    _waveAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _controllerAnim, curve: Curves.easeInOut),
    );

    _messages.add({
      'role': 'bot',
      'message': "Merhaba, ben Vita. Size nasıl yardımcı olabilirim?",
    });
    
    // Modeli ön yükle
    _preloadModel();
  }
  
  // Model ön yükleme fonksiyonu
  Future<void> _preloadModel() async {
    try {
      print('Model kontrol ediliyor...');
      
      // Önce mevcut modelleri kontrol et
      final availableModels = await _getAvailableModels();
      print('Mevcut modeller: $availableModels');
      
      if (availableModels.isNotEmpty) {
        print('Model hazır!');
      } else {
        print('Hiç model bulunamadı!');
        setState(() {
          _messages.add({
            'role': 'bot',
            'message': "Üzgünüm, hiç AI modeli yüklü değil. Lütfen 'ollama pull tinyllama' komutunu çalıştırın.",
          });
        });
      }
    } catch (e) {
      print('Model kontrol hatası: $e');
    }
  }

  // Mevcut modelleri getir
  Future<List<String>> _getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:11434/api/tags'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List?)
            ?.map((model) => model['name'].toString())
            .toList() ?? [];
        return models;
      }
    } catch (e) {
      print('Model listesi alma hatası: $e');
    }
    return [];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _controllerAnim.dispose();
    super.dispose();
  }

  // Ollama API'sine istek gönderen fonksiyon
  Future<String> _sendToOllama(String message) async {
    try {
      print('Ollama\'ya istek gönderiliyor: $ollamaUrl');
      print('Model: $modelName');
      print('Mesaj: $message');
      
      final response = await http.post(
        Uri.parse(ollamaUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelName,
          'prompt': message,
          'stream': false,
          'options': {
            'num_predict': 128,  // Maksimum token sayısını sınırla
            'temperature': 0.7,  // Yaratıcılık seviyesi
            'top_p': 0.9,       // Nucleus sampling
            'top_k': 40,        // Top-k sampling
          }
        }),
      ).timeout(const Duration(seconds: 180)); // Timeout'u 3 dakikaya çıkardık

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Üzgünüm, yanıt alamadım.';
      } else if (response.statusCode == 404) {
        return 'Model "$modelName" bulunamadı. Lütfen şu komutları çalıştırın:\n\nollama pull $modelName\n\nVeya mevcut modelleri kontrol edin:\nollama list';
      } else {
        print('Ollama API Hatası: ${response.statusCode}');
        return 'API Hatası (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('Detaylı Hata: $e');
      if (e.toString().contains('Connection refused')) {
        return 'Ollama sunucusu çalışmıyor. Lütfen "ollama serve" komutunu çalıştırın.';
      } else if (e.toString().contains('TimeoutException')) {
        return 'Model yükleniyor veya çok yavaş yanıt veriyor. Lütfen bekleyin veya daha küçük bir model deneyin.';
      }
      return 'Bağlantı hatası: ${e.toString()}';
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Ollama'dan yanıt al
      final response = await _sendToOllama(text);
      
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'bot', 'message': response});
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot', 
          'message': 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.'
        });
      });
      
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildMessage(
    Map<String, String> msg,
    double fontSize,
    double avatarRadius,
  ) {
    final isUser = msg['role'] == 'user';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/vita_avatar.png'),
              radius: avatarRadius,
            ),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? AppColors.vibrantPink.withOpacity(0.3)
                        : AppColors.vibrantPurple.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                msg['message'] ?? '',
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double titleFontSize, double avatarRadius) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 10, right: 10),
      child: Row(
        children: [
          const SizedBox(width: 5),
          CircleAvatar(
            backgroundImage: AssetImage('assets/images/vita_avatar.png'),
            radius: avatarRadius,
          ),
          const SizedBox(width: 20),
          AnimatedBuilder(
            animation: _controllerAnim,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _waveAnimation.value),
                  child: Text(
                    "Vita",
                    style: AppStyles.pageTitle.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: _colorAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    final avatarRadius = screenWidth * 0.06;
    final titleFontSize = screenWidth * 0.07;
    final messageFontSize = screenWidth * 0.04;
    final paddingHorizontal = screenWidth * 0.04;
    final inputFontSize = screenWidth * 0.045;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.vibrantBlue.withOpacity(0.3),
                AppColors.vibrantPurple.withOpacity(0.3),
                AppColors.vibrantPink.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                _buildHeader(titleFontSize, avatarRadius),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child:
                      _messages.isEmpty
                          ? Center(
                            child: Text(
                              "Henüz mesaj yok.",
                              style: TextStyle(fontSize: messageFontSize),
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            padding: const EdgeInsets.only(top: 16),
                            itemBuilder:
                                (context, index) => _buildMessage(
                                  _messages[index],
                                  messageFontSize,
                                  avatarRadius,
                                ),
                          ),
                ),
                if (_isTyping)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingHorizontal,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/vita_avatar.png',
                          ),
                          radius: avatarRadius * 0.8,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Vita yazıyor",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textColor,
                            fontSize: inputFontSize,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const LoadingIndicator(),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(fontSize: inputFontSize),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              hintText: "Mesajınızı yazın...",
                              hintStyle: TextStyle(color: AppColors.textColor),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.vibrantPurple,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send,
                            color: AppColors.primaryColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({super.key});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _dotAnimation = StepTween(begin: 1, end: 3).animate(_dotsController);
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Text(
          "." * _dotAnimation.value,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.greyColor,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}