import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  bool _isSpeaking = false;
  
  // Initialize text to speech
  FlutterTts? _flutterTts;
  final ImagePicker _imagePicker = ImagePicker();
  int? _currentSpeakingMessageIndex;
  bool _ttsAvailable = false;
  
  // Multilingual support
  List<Map<String, String>> _languages = [];
  String _currentLanguage = "en-US";
  String _currentLanguageCode = "en";
  String _currentCountryCode = "US";
  String _currentLanguageName = "English (US)";
  bool _isLanguageDialogOpen = false;

  final List<String> _quickSuggestions = [
    "How can I optimize my living room?",
    "Give me tips for small spaces",
    "What's the best layout for my office?",
    "Help with furniture arrangement"
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    // Add welcome message sequence from bot
    _addBotWelcomeSequence();
  }
  
  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();
      
      // Ensure we show the language button regardless of TTS availability check
      _ttsAvailable = true;
      
      // Check if TTS is available before attempting to use it
      if (Platform.isIOS || Platform.isAndroid) {
        // Get available languages
        try {
          _languages = await _getLanguages();
          debugPrint('Available languages: ${_languages.length}');
        } catch (e) {
          debugPrint('Error getting languages: $e');
          _languages = [
            {"name": "English (US)", "locale": "en-US"},
            {"name": "Hindi", "locale": "hi-IN"},
            {"name": "Spanish", "locale": "es-ES"},
            {"name": "French", "locale": "fr-FR"},
            {"name": "German", "locale": "de-DE"},
            {"name": "Chinese", "locale": "zh-CN"},
            {"name": "Japanese", "locale": "ja-JP"},
          ];
        }
        
        // Even if language check fails, we'll still show the UI
        try {
          var available = await _flutterTts?.isLanguageAvailable(_currentLanguage);
          if (available != 1) {
            debugPrint('The selected language is not available, but showing UI anyway');
          }
        } catch (e) {
          debugPrint('Language availability check failed: $e');
        }
        
        try {
          await _flutterTts?.setLanguage(_currentLanguage);
          await _flutterTts?.setSpeechRate(0.5);
          await _flutterTts?.setVolume(1.0);
          await _flutterTts?.setPitch(1.0);
          
          // Only set handlers if the platform is supported
          _flutterTts?.setCompletionHandler(() {
            if (mounted) {
              setState(() {
                _isSpeaking = false;
                _currentSpeakingMessageIndex = null;
              });
            }
          });
          
          _flutterTts?.setErrorHandler((error) {
            if (mounted) {
              setState(() {
                _isSpeaking = false;
                _currentSpeakingMessageIndex = null;
              });
              debugPrint('TTS Error: $error');
            }
          });
        } catch (e) {
          debugPrint('TTS setup error: $e');
        }
      } else {
        debugPrint('TTS not supported on this platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }
  
  Future<List<Map<String, String>>> _getLanguages() async {
    List<Map<String, String>> result = [];
    try {
      List<dynamic>? languages = await _flutterTts?.getLanguages;
      
      if (languages != null) {
        for (var lang in languages) {
          String langCode = lang.toString();
          String displayName = await _getLanguageDisplayName(langCode);
          result.add({
            "name": displayName,
            "locale": langCode,
          });
        }
      }
      
      // Sort languages alphabetically by name
      result.sort((a, b) => a["name"]!.compareTo(b["name"]!));
      
      return result;
    } catch (e) {
      debugPrint('Error getting languages: $e');
      // Return fallback languages if we can't get the list
      return [
        {"name": "English (US)", "locale": "en-US"},
        {"name": "Hindi", "locale": "hi-IN"},
        {"name": "Spanish", "locale": "es-ES"},
        {"name": "French", "locale": "fr-FR"},
        {"name": "German", "locale": "de-DE"},
      ];
    }
  }
  
  Future<String> _getLanguageDisplayName(String localeCode) async {
    try {
      // Parse language and country codes
      List<String> parts = localeCode.split('-');
      String langCode = parts[0].toLowerCase();
      String countryCode = parts.length > 1 ? parts[1].toUpperCase() : "";
      
      // Map of language codes to names - add more as needed
      Map<String, String> languageNames = {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'it': 'Italian',
        'pt': 'Portuguese',
        'ru': 'Russian',
        'ja': 'Japanese',
        'ko': 'Korean',
        'zh': 'Chinese',
        'ar': 'Arabic',
        'hi': 'Hindi',
        'bn': 'Bengali',
        'pa': 'Punjabi',
        'ta': 'Tamil',
        'te': 'Telugu',
        'mr': 'Marathi',
        'gu': 'Gujarati',
        'kn': 'Kannada',
        'ml': 'Malayalam',
      };
      
      // Map of country codes to names - add more as needed
      Map<String, String> countryNames = {
        'US': 'US',
        'GB': 'UK',
        'IN': 'India',
        'AU': 'Australia',
        'CA': 'Canada',
        'ES': 'Spain',
        'MX': 'Mexico',
        'FR': 'France',
        'DE': 'Germany',
        'IT': 'Italy',
        'JP': 'Japan',
        'KR': 'Korea',
        'CN': 'China',
        'TW': 'Taiwan',
        'HK': 'Hong Kong',
      };
      
      String langName = languageNames[langCode] ?? langCode;
      
      if (countryCode.isNotEmpty && countryNames.containsKey(countryCode)) {
        return '$langName (${countryNames[countryCode]})';
      } else if (countryCode.isNotEmpty) {
        return '$langName ($countryCode)';
      } else {
        return langName;
      }
    } catch (e) {
      // Return the original code if anything goes wrong
      return localeCode;
    }
  }
  
  Future<void> _changeLanguage(String locale, String name) async {
    try {
      // Set new language
      setState(() {
        _currentLanguage = locale;
        _currentLanguageName = name;
        
        // Parse language and country codes
        List<String> parts = locale.split('-');
        _currentLanguageCode = parts[0].toLowerCase();
        _currentCountryCode = parts.length > 1 ? parts[1].toUpperCase() : "";
      });
      
      // Stop any current speech
      await _stopSpeaking();
      
      // Apply new language
      if (_flutterTts != null) {
        var available = await _flutterTts?.isLanguageAvailable(locale);
        if (available == 1) {
          await _flutterTts?.setLanguage(locale);
          
          // Add a message about the language change
          _addBotMessage("I'm now speaking in $_currentLanguageName.");
          
          // Test the new language if it's available
          if (_ttsAvailable) {
            setState(() {
              _isSpeaking = true;
              _currentSpeakingMessageIndex = -1; // Special value for language test
            });
            
            try {
              await _flutterTts?.speak("Hello, I'm now speaking in $_currentLanguageName");
            } catch (e) {
              debugPrint('Error testing language: $e');
            }
          }
        } else {
          // If the language is not available, inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language $name is not available on this device'),
              duration: const Duration(seconds: 3),
            ),
          );
          _ttsAvailable = false;
        }
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing language: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _addBotWelcomeSequence() async {
    _addBotMessage("Hello! I'm your Space Optimization Assistant. 👋");
    await Future.delayed(const Duration(milliseconds: 600));
    _addBotMessage("I can help you optimize your space by analyzing images, suggesting layouts, and offering personalized recommendations.");
    await Future.delayed(const Duration(milliseconds: 800));
    _addBotMessage("How can I assist you today?");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _stopSpeaking();
    if (_flutterTts != null) {
      _flutterTts?.stop();
    }
    super.dispose();
  }
  
  Future<void> _stopSpeaking() async {
    if (_isSpeaking && _ttsAvailable) {
      try {
        await _flutterTts?.stop();
      } catch (e) {
        debugPrint('TTS stop error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageIndex = null;
          });
        }
      }
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    // Hide suggestions once user starts typing
    setState(() {
      _showSuggestions = false;
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate response delay (this will be replaced by FastAPI call)
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock response (will be replaced with actual FastAPI response)
    final String botResponse = _generateMockResponse(userMessage);
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _useSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _handleSendMessage();
  }

  Future<void> _speakMessage(String message, int messageIndex) async {
    try {
      // If we're already speaking the same message, stop it and return
      if (_isSpeaking && _currentSpeakingMessageIndex == messageIndex) {
        await _stopSpeaking();
        // Add haptic feedback for button press
        if (mounted) {
          HapticFeedback.lightImpact();
        }
        return;
      }
      
      // If we're speaking a different message, stop it first
      if (_isSpeaking) {
        await _stopSpeaking();
      }
      
      // Add haptic feedback for button press
      if (mounted) {
        HapticFeedback.lightImpact();
      }
      
      setState(() {
        _isSpeaking = true;
        _currentSpeakingMessageIndex = messageIndex;
      });
      
      // Clean the message for better TTS results
      String cleanMessage = message
          .replaceAll('\n', '. ')
          .replaceAll('•', '')
          .replaceAll('  ', ' ');
      
      if (_flutterTts != null) {
        try {
          await _flutterTts?.speak(cleanMessage);
        } catch (e) {
          debugPrint('TTS speak call error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech function unavailable. Please reinstall the app or use another device.'),
              duration: Duration(seconds: 3),
            ),
          );
          
          // Reset speaking state
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageIndex = null;
          });
        }
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      setState(() {
        _isSpeaking = false;
        _currentSpeakingMessageIndex = null;
      });
      
      // If there's an error with TTS, show a fallback visual message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech function unavailable: ${e.toString().substring(0, math.min(e.toString().length, 50))}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _pickImageForAnalysis() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Navigate to Analysis tab
        _navigateToAnalysisTab();
        
        // Add a message about the analysis
        _addBotMessage("I've redirected you to the Analysis tab. Please use the Space Optimization feature there to analyze your image.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _navigateToAnalysisTab() {
    // This is a simplistic approach - in a real app, you would use a more robust navigation system
    // For now, this will rely on the parent widget (likely LayoutPage) to handle the tab change
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Please select the Analysis tab to proceed with image analysis'),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Add a message to guide the user to the Analysis tab
    _addBotMessage("To analyze your image, please tap on the Analysis tab in the bottom navigation bar.");
  }

  String _generateMockResponse(String userMessage) {
    final String lowercaseMessage = userMessage.toLowerCase();
    
    if (lowercaseMessage.contains('hello') || lowercaseMessage.contains('hi')) {
      return 'Hello! How can I assist you with space optimization today?';
    } else if (lowercaseMessage.contains('living room') || lowercaseMessage.contains('optimize')) {
      return 'For living room optimization, I recommend considering these key factors:\n\n1. Traffic flow - ensure there\'s a clear path through the room\n2. Focal point - arrange furniture around a natural focal point\n3. Conversation areas - position seating for easy interaction\n4. Scale and proportion - choose furniture that fits the room size\n\nWould you like to upload an image of your space for specific recommendations?';
    } else if (lowercaseMessage.contains('small space')) {
      return 'Small spaces can be challenging! Here are some optimization tips:\n\n• Use multi-functional furniture (sofa beds, nesting tables)\n• Maximize vertical space with tall shelving\n• Choose light colors to create an illusion of space\n• Use mirrors strategically to reflect light\n• Consider built-in storage solutions\n\nFor more tailored advice, try uploading a photo of your space.';
    } else if (lowercaseMessage.contains('office') || lowercaseMessage.contains('layout')) {
      return 'For an optimal office layout, consider:\n\n• Position your desk to face the entrance if possible\n• Ensure adequate lighting, preferably natural light\n• Separate work zones based on activities\n• Keep frequently used items within arm\'s reach\n• Add plants for better air quality and mood\n\nDo you have specific office constraints you\'d like help with?';
    } else if (lowercaseMessage.contains('furniture') || lowercaseMessage.contains('arrangement')) {
      return 'Effective furniture arrangement follows these principles:\n\n• Leave sufficient walking space (18-24 inches between pieces)\n• Create balance with furniture sizes and placement\n• Consider the room\'s purpose and traffic patterns\n• Arrange seating for conversation (no more than 8 feet apart)\n• Float furniture away from walls in larger rooms\n\nWould you like to see some layout examples?';
    } else if (lowercaseMessage.contains('thanks') || lowercaseMessage.contains('thank you')) {
      return 'You\'re welcome! Feel free to ask if you need any more help with your space optimization.';
    } else if (lowercaseMessage.contains('image') || lowercaseMessage.contains('upload') || lowercaseMessage.contains('photo')) {
      return 'To upload an image for analysis, please go to the Analysis tab and select the Space Optimization feature. After uploading, I can provide customized recommendations based on your specific space.';
    } else if (lowercaseMessage.contains('speak') || lowercaseMessage.contains('voice') || lowercaseMessage.contains('talk')) {
      return 'I can read messages aloud for you. Just tap the speaker icon on any message to hear it spoken. Tap again to stop the speech.';
    } else {
      return 'I understand you\'re interested in space optimization. Could you please be more specific about your space or the challenges you\'re facing? Alternatively, you can upload a photo in the Analysis tab for personalized suggestions.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLanguageSelectionDialog() {
    setState(() {
      _isLanguageDialogOpen = true;
    });
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final bool isSelected = language["locale"] == _currentLanguage;
                
                return ListTile(
                  title: Text(language["name"] ?? "Unknown"),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeLanguage(
                      language["locale"] ?? "en-US",
                      language["name"] ?? "English",
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLanguageDialogOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Space Assistant',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '• Online',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Always show language selector button, regardless of TTS availability
                    InkWell(
                      onTap: _showLanguageSelectionDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentLanguageCode.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your personal space optimization guide',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      // Show typing indicator as the last item when bot is typing
                      return _buildTypingIndicator(context);
                    }
                    return _buildMessageItem(context, _messages[index], index);
                  },
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),
          ),
          if (_showSuggestions && _messages.length < 5) _buildQuickSuggestions(),
          _buildInputField(context),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _useSuggestion(_quickSuggestions[index]),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  _quickSuggestions[index],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickImageForAnalysis,
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: Colors.grey[500],
                    ),
                    tooltip: 'Upload an image for analysis',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      onChanged: (text) {
                        // Hide suggestions once user starts typing
                        if (text.isNotEmpty && _showSuggestions) {
                          setState(() {
                            _showSuggestions = false;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSendMessage,
                    icon: Icon(
                      Icons.send_rounded,
                      color: Theme.of(context).colorScheme.primary,
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

  Widget _buildMessageItem(BuildContext context, ChatMessage message, int index) {
    final bool isCurrentlySpeaking = _isSpeaking && _currentSpeakingMessageIndex == index;
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                // Always show speech icon for bot messages, regardless of TTS availability check
                if (!message.isUser) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _speakMessage(message.text, index),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isCurrentlySpeaking
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: isCurrentlySpeaking
                              ? _buildSpeakingIcon(context)
                              : Icon(
                                  Icons.volume_up_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(
          begin: message.isUser ? 0.2 : -0.2,
          end: 0,
          duration: 200.ms,
        );
  }
  
  Widget _buildSpeakingIcon(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.volume_up,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          ...List.generate(2, (index) {
            return Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scaleXY(
              begin: 0.8,
              end: 1.8,
              duration: const Duration(milliseconds: 1000),
              delay: Duration(milliseconds: index * 400),
              curve: Curves.easeOutQuad,
            ).fadeOut(
              duration: const Duration(milliseconds: 1000),
              delay: Duration(milliseconds: index * 400),
              curve: Curves.easeOutQuad,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulsingDot(context),
            const SizedBox(width: 4),
            _buildPulsingDot(context, delay: 200),
            const SizedBox(width: 4),
            _buildPulsingDot(context, delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot(BuildContext context, {int delay = 0}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scaleXY(
      begin: 0.6,
      end: 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      delay: Duration(milliseconds: delay),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
} 