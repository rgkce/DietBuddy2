import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

  // Gemini API konfigürasyonu
  static const String _apiKey =
      'AIzaSyD1SBeCKhHvZ9K9KNzc9YwxtoAjgqkUbdc'; // API anahtarınızı buraya yazın
  late GenerativeModel _model;
  ChatSession? _chatSession;

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
      'message': "Hi, I'm Vita. How can I help you with nutrition?",
    });

    _initializeGemini();
  }

  // Gemini modelini başlatma fonksiyonu
  void _initializeGemini() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.system(
          'Sen Vita, bir beslenme uzmanı asistanısın. Kullanıcılara sağlıklı beslenme, '
          'diyet önerileri, kalori hesaplama ve genel sağlık konularında yardımcı oluyorsun. '
          'Samimi, profesyonel ve yardımsever bir tonda konuş. Türkçe yanıt ver.'
          'Cevapların kısa özetler halinde olsun',
        ),
      );

      _chatSession = _model.startChat();
      debugPrint('Gemini model başarıyla başlatıldı');
    } catch (e) {
      debugPrint('Gemini başlatma hatası: $e');
      setState(() {
        _messages.add({
          'role': 'bot',
          'message':
              "Üzgünüm, şu anda AI servisimde bir sorun var. Lütfen daha sonra tekrar deneyin.",
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _controllerAnim.dispose();
    super.dispose();
  }

  // Gemini API'sine istek gönderen fonksiyon
  Future<String> _sendToGemini(String message) async {
    try {
      if (_chatSession == null) {
        throw Exception('Chat session başlatılamadı');
      }

      debugPrint('Gemini\'ye mesaj gönderiliyor: $message');

      final response = await _chatSession!.sendMessage(Content.text(message));

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Üzgünüm, şu anda size yardımcı olamıyorum. Lütfen sorunuzu farklı şekilde sormayı deneyin.';
      }
    } catch (e) {
      debugPrint('Gemini API Hatası: $e');

      if (e.toString().contains('API_KEY')) {
        return 'API anahtarı hatası. Lütfen geliştirici ile iletişime geçin.';
      } else if (e.toString().contains('SAFETY')) {
        return 'Güvenlik nedeniyle bu soruya yanıt veremiyorum. Lütfen farklı bir soru sorun.';
      } else if (e.toString().contains('QUOTA_EXCEEDED')) {
        return 'Günlük kullanım limitine ulaşıldı. Lütfen yarın tekrar deneyin.';
      } else if (e.toString().contains('network')) {
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      } else {
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Gemini'den yanıt al
      final response = await _sendToGemini(text);

      setState(() {
        _isTyping = false;
        _messages.add({'role': 'bot', 'message': response});
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'message': 'Error: Could not connect to AI service.',
        });
      });
    }
    _scrollToBottom();
  }

  void _sendMessageWithStream() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _controller.clear();
      _isTyping = true;
      _messages.add({'role': 'bot', 'message': '', 'isStreaming': 'true'});
    });

    _scrollToBottom();

    try {
      final response = _model.generateContentStream([Content.text(text)]);
      String fullResponse = '';

      await for (final chunk in response) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;
          if (mounted) {
            setState(() {
              _messages.last = {
                'role': 'bot',
                'message': fullResponse,
                'isStreaming': 'true',
              };
            });
            _scrollToBottom();
          }
        }
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.last = {'role': 'bot', 'message': fullResponse};
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.last = {
            'role': 'bot',
            'message': 'Error during streaming.',
          };
        });
      }
    }
    _scrollToBottom();
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'bot',
        'message': "Hi, I'm Vita. How can I help you with nutrition?",
      });
    });

    // Restart chat session
    _chatSession = _model.startChat();
  }

  Widget _buildMessage(
    Map<String, String> msg,
    double fontSize,
    double avatarRadius,
  ) {
    final isUser = msg['role'] == 'user';
    final isStreaming = msg['isStreaming'] == 'true';

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
                        ? AppColors.vibrantPink.withValues(alpha: 0.3)
                        : AppColors.vibrantPurple.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['message'] ?? '',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  if (isStreaming && !isUser)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.vibrantPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vita is typing...',
                            style: TextStyle(
                              fontSize: fontSize * 0.8,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
          Expanded(
            child: AnimatedBuilder(
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
          ),
          // Temizle butonu
          IconButton(
            onPressed: _clearChat,
            icon: Icon(
              Icons.refresh,
              color: AppColors.vibrantPurple,
              size: titleFontSize,
            ),
            tooltip: 'Clear Chat',
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
    final titleFontSize = screenWidth * 0.06; // Başlık boyutunu küçülttüm
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
                AppColors.vibrantBlue.withValues(alpha: 0.3),
                AppColors.vibrantPurple.withValues(alpha: 0.3),
                AppColors.vibrantPink.withValues(alpha: 0.3),
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
                              "No message yet.",
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
                          "Vita is typing",
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
                                color: AppColors.shadowColor.withValues(
                                  alpha: 0.3,
                                ),
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
                              hintText: "Ask about nutrition...",
                              hintStyle: TextStyle(color: AppColors.textColor),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !_isTyping,
                            maxLines: null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Streaming mesaj butonu
                      GestureDetector(
                        onTap: _isTyping ? null : _sendMessageWithStream,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                _isTyping
                                    ? AppColors.greyColor
                                    : AppColors.button,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Normal mesaj butonu
                      GestureDetector(
                        onTap: _isTyping ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _isTyping
                                    ? AppColors.greyColor
                                    : AppColors.vibrantPurple,
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
