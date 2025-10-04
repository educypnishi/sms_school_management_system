import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AIChatbotService {
  static final AIChatbotService _instance = AIChatbotService._internal();
  factory AIChatbotService() => _instance;
  AIChatbotService._internal();

  // Chatbot configuration
  static const String _conversationHistoryKey = 'chatbot_conversations';
  static const String _userPreferencesKey = 'chatbot_preferences';
  static const int maxConversationHistory = 50;
  static const int responseDelayMs = 1500; // Simulate AI processing time

  // Pakistani school context knowledge base
  final Map<String, List<String>> _knowledgeBase = {
    // Academic queries
    'grades': [
      'Your current grades are available in the Performance section of your dashboard.',
      'To check your grades, go to Quick Actions → Performance → View Grades.',
      'Grades are updated by teachers after each assessment. Check regularly for updates.',
    ],
    'attendance': [
      'Your attendance percentage is shown on the main dashboard.',
      'To view detailed attendance, click on Quick Actions → Attendance.',
      'Minimum 75% attendance is required as per Pakistani education standards.',
    ],
    'timetable': [
      'Your class schedule is available in Today\'s Classes on the dashboard.',
      'For full timetable, go to Quick Actions → Calendar.',
      'Classes typically run from 8:00 AM to 2:00 PM in Pakistani schools.',
    ],
    'exams': [
      'Upcoming exams are shown on your dashboard with countdown timers.',
      'Exam schedules follow the Pakistani academic calendar.',
      'Mid-term exams are usually in October and March, finals in May and December.',
    ],
    
    // Fee-related queries
    'fees': [
      'Your fee summary is displayed on the main dashboard.',
      'To pay fees, click the "Pay Fees" button or go to Quick Actions → Documents.',
      'Fee structure includes tuition, books, and activity charges as per Pakistani standards.',
    ],
    'payment': [
      'We accept payments through 7 major Pakistani banks including HBL, UBL, and MCB.',
      'Online payment is secure and instant. You\'ll receive a confirmation SMS.',
      'Fee installments can be paid monthly or quarterly as per school policy.',
    ],
    
    // Technical support
    'login': [
      'If you\'re having trouble logging in, check your username and password.',
      'Use the "Forgot Password" option if you need to reset your password.',
      'Contact your class teacher if login issues persist.',
    ],
    'password': [
      'Passwords must be at least 8 characters with uppercase, lowercase, numbers, and symbols.',
      'Change your password regularly for security.',
      'Never share your login credentials with anyone.',
    ],
    
    // Pakistani school context
    'uniform': [
      'School uniform requirements are available in the Documents section.',
      'Summer uniform is typically white shirt with navy/grey pants/skirt.',
      'Winter uniform includes blazer and tie as per Pakistani school traditions.',
    ],
    'holidays': [
      'School holidays follow the Pakistani academic calendar.',
      'Major holidays include Eid, Independence Day (14th August), and winter break.',
      'Holiday notifications are sent through the app and SMS.',
    ],
    'transport': [
      'School transport routes and timings are available in the Documents section.',
      'Transport fee is separate from tuition fee.',
      'Contact the admin office for transport-related queries.',
    ],
    
    // General help
    'help': [
      'I\'m here to help with academic, fee, and general school queries.',
      'You can ask about grades, attendance, fees, exams, or any school-related topic.',
      'For urgent matters, contact your class teacher or school admin.',
    ],
    'contact': [
      'Contact your class teacher through the Messages section.',
      'Admin office hours: 8:00 AM to 4:00 PM, Monday to Friday.',
      'Emergency contact number is available in your student handbook.',
    ],
  };

  // Urdu language support
  final Map<String, String> _urduTranslations = {
    'hello': 'السلام علیکم! میں آپ کی کیسے مدد کر سکتا ہوں؟',
    'grades': 'آپ کے نمبرات ڈیش بورڈ کے Performance سیکشن میں دستیاب ہیں۔',
    'fees': 'آپ کی فیس کی تفصیلات ڈیش بورڈ پر دکھائی گئی ہیں۔',
    'attendance': 'آپ کی حاضری کی فیصد ڈیش بورڈ پر دکھائی گئی ہے۔',
    'help': 'میں تعلیمی، فیس، اور اسکول سے متعلق سوالات میں آپ کی مدد کر سکتا ہوں۔',
  };

  /// Send message to AI chatbot
  Future<ChatbotResponse> sendMessage({
    required String userId,
    required String message,
    String? language = 'en',
  }) async {
    try {
      // Store user message
      await _storeMessage(userId, ChatMessage(
        id: _generateMessageId(),
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        language: language ?? 'en',
      ));

      // Simulate AI processing delay
      await Future.delayed(const Duration(milliseconds: responseDelayMs));

      // Generate AI response
      final response = await _generateResponse(userId, message, language ?? 'en');

      // Store AI response
      await _storeMessage(userId, ChatMessage(
        id: _generateMessageId(),
        content: response.content,
        isUser: false,
        timestamp: DateTime.now(),
        language: language ?? 'en',
        confidence: response.confidence,
        intent: response.intent,
      ));

      return response;
    } catch (e) {
      debugPrint('Error sending message to chatbot: $e');
      return ChatbotResponse(
        content: 'Sorry, I\'m having trouble processing your request. Please try again.',
        confidence: 0.0,
        intent: ChatIntent.error,
        suggestions: ['Try rephrasing your question', 'Contact support'],
      );
    }
  }

  /// Get conversation history
  Future<List<ChatMessage>> getConversationHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getString('${_conversationHistoryKey}_$userId');
      
      if (historyData == null) return [];
      
      final historyJson = jsonDecode(historyData) as List;
      return historyJson.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  /// Clear conversation history
  Future<void> clearConversationHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_conversationHistoryKey}_$userId');
    } catch (e) {
      debugPrint('Error clearing conversation history: $e');
    }
  }

  /// Get chatbot analytics
  Future<ChatbotAnalytics> getChatbotAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allConversations = await _getAllConversations();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      var messages = <ChatMessage>[];
      
      // Collect messages from all users or specific user
      for (final entry in allConversations.entries) {
        if (userId == null || entry.key == userId) {
          final userMessages = entry.value.where((msg) => 
            msg.timestamp.isAfter(start) && msg.timestamp.isBefore(end)
          ).toList();
          messages.addAll(userMessages);
        }
      }
      
      // Calculate analytics
      final totalMessages = messages.length;
      final userMessages = messages.where((m) => m.isUser).length;
      final botMessages = messages.where((m) => !m.isUser).length;
      
      // Intent breakdown
      final intentCounts = <ChatIntent, int>{};
      for (final message in messages.where((m) => !m.isUser)) {
        final intent = message.intent ?? ChatIntent.general;
        intentCounts[intent] = (intentCounts[intent] ?? 0) + 1;
      }
      
      // Average confidence
      final confidenceScores = messages
          .where((m) => !m.isUser && m.confidence != null)
          .map((m) => m.confidence!)
          .toList();
      
      final averageConfidence = confidenceScores.isNotEmpty
          ? confidenceScores.reduce((a, b) => a + b) / confidenceScores.length
          : 0.0;
      
      // Most common queries
      final queryTypes = <String, int>{};
      for (final message in messages.where((m) => m.isUser)) {
        final intent = _detectIntent(message.content);
        final intentName = intent.toString().split('.').last;
        queryTypes[intentName] = (queryTypes[intentName] ?? 0) + 1;
      }
      
      return ChatbotAnalytics(
        totalMessages: totalMessages,
        userMessages: userMessages,
        botMessages: botMessages,
        averageConfidence: averageConfidence,
        intentBreakdown: intentCounts,
        commonQueries: queryTypes,
        period: DateRange(start, end),
      );
    } catch (e) {
      debugPrint('Error getting chatbot analytics: $e');
      return ChatbotAnalytics(
        totalMessages: 0,
        userMessages: 0,
        botMessages: 0,
        averageConfidence: 0.0,
        intentBreakdown: {},
        commonQueries: {},
        period: DateRange(DateTime.now(), DateTime.now()),
      );
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(String userId, ChatbotPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_userPreferencesKey}_$userId', jsonEncode(preferences.toJson()));
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }

  /// Get user preferences
  Future<ChatbotPreferences> getUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsData = prefs.getString('${_userPreferencesKey}_$userId');
      
      if (prefsData != null) {
        final prefsJson = jsonDecode(prefsData);
        return ChatbotPreferences.fromJson(prefsJson);
      }
      
      return ChatbotPreferences.defaultPreferences();
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return ChatbotPreferences.defaultPreferences();
    }
  }

  // Private helper methods

  Future<ChatbotResponse> _generateResponse(String userId, String message, String language) async {
    try {
      // Detect intent
      final intent = _detectIntent(message);
      
      // Get user preferences
      final preferences = await getUserPreferences(userId);
      
      // Generate response based on intent
      String responseContent;
      double confidence;
      List<String> suggestions = [];
      
      switch (intent) {
        case ChatIntent.greeting:
          responseContent = _getGreetingResponse(language);
          confidence = 0.95;
          suggestions = ['Ask about grades', 'Check fees', 'View attendance'];
          break;
          
        case ChatIntent.academic:
          responseContent = _getAcademicResponse(message, language);
          confidence = 0.85;
          suggestions = ['View grades', 'Check timetable', 'Upcoming exams'];
          break;
          
        case ChatIntent.fees:
          responseContent = _getFeesResponse(message, language);
          confidence = 0.90;
          suggestions = ['Pay fees', 'View fee structure', 'Payment methods'];
          break;
          
        case ChatIntent.technical:
          responseContent = _getTechnicalResponse(message, language);
          confidence = 0.80;
          suggestions = ['Reset password', 'Contact support', 'Check system status'];
          break;
          
        case ChatIntent.general:
          responseContent = _getGeneralResponse(message, language);
          confidence = 0.70;
          suggestions = ['Ask about grades', 'Check fees', 'Get help'];
          break;
          
        case ChatIntent.urdu:
          responseContent = _getUrduResponse(message);
          confidence = 0.75;
          suggestions = ['نمبرات دیکھیں', 'فیس چیک کریں', 'مدد حاصل کریں'];
          break;
          
        default:
          responseContent = _getDefaultResponse(language);
          confidence = 0.60;
          suggestions = ['Try asking about grades', 'Ask about fees', 'Get general help'];
      }
      
      return ChatbotResponse(
        content: responseContent,
        confidence: confidence,
        intent: intent,
        suggestions: suggestions,
      );
    } catch (e) {
      debugPrint('Error generating response: $e');
      return ChatbotResponse(
        content: 'I apologize, but I\'m having trouble understanding your question. Could you please rephrase it?',
        confidence: 0.0,
        intent: ChatIntent.error,
        suggestions: ['Try rephrasing', 'Ask about grades', 'Contact support'],
      );
    }
  }

  ChatIntent _detectIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Greeting patterns
    if (RegExp(r'\b(hello|hi|hey|salam|assalam)\b').hasMatch(lowerMessage)) {
      return ChatIntent.greeting;
    }
    
    // Urdu language detection
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(message)) {
      return ChatIntent.urdu;
    }
    
    // Academic patterns
    if (RegExp(r'\b(grade|marks|result|exam|test|assignment|homework|study)\b').hasMatch(lowerMessage)) {
      return ChatIntent.academic;
    }
    
    // Fee patterns
    if (RegExp(r'\b(fee|fees|payment|pay|money|bill|tuition|cost)\b').hasMatch(lowerMessage)) {
      return ChatIntent.fees;
    }
    
    // Technical patterns
    if (RegExp(r'\b(login|password|account|error|bug|problem|issue|help)\b').hasMatch(lowerMessage)) {
      return ChatIntent.technical;
    }
    
    return ChatIntent.general;
  }

  String _getGreetingResponse(String language) {
    if (language == 'ur') {
      return _urduTranslations['hello'] ?? 'السلام علیکم! میں آپ کی کیسے مدد کر سکتا ہوں؟';
    }
    
    final greetings = [
      'Hello! I\'m your AI assistant for school-related queries. How can I help you today?',
      'Hi there! I\'m here to help with your academic, fee, and general school questions.',
      'Welcome! I can assist you with grades, attendance, fees, and other school matters.',
    ];
    
    return greetings[Random().nextInt(greetings.length)];
  }

  String _getAcademicResponse(String message, String language) {
    if (language == 'ur') {
      return _urduTranslations['grades'] ?? 'آپ کے نمبرات ڈیش بورڈ کے Performance سیکشن میں دستیاب ہیں۔';
    }
    
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('grade') || lowerMessage.contains('marks')) {
      return _getRandomResponse(_knowledgeBase['grades']!);
    } else if (lowerMessage.contains('attendance')) {
      return _getRandomResponse(_knowledgeBase['attendance']!);
    } else if (lowerMessage.contains('exam') || lowerMessage.contains('test')) {
      return _getRandomResponse(_knowledgeBase['exams']!);
    } else if (lowerMessage.contains('timetable') || lowerMessage.contains('schedule')) {
      return _getRandomResponse(_knowledgeBase['timetable']!);
    }
    
    return 'I can help you with grades, attendance, exams, and timetable. What specific information do you need?';
  }

  String _getFeesResponse(String message, String language) {
    if (language == 'ur') {
      return _urduTranslations['fees'] ?? 'آپ کی فیس کی تفصیلات ڈیش بورڈ پر دکھائی گئی ہیں۔';
    }
    
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('pay') || lowerMessage.contains('payment')) {
      return _getRandomResponse(_knowledgeBase['payment']!);
    } else {
      return _getRandomResponse(_knowledgeBase['fees']!);
    }
  }

  String _getTechnicalResponse(String message, String language) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('login') || lowerMessage.contains('account')) {
      return _getRandomResponse(_knowledgeBase['login']!);
    } else if (lowerMessage.contains('password')) {
      return _getRandomResponse(_knowledgeBase['password']!);
    } else {
      return 'For technical issues, please contact your class teacher or school admin. I can also help with basic login and password questions.';
    }
  }

  String _getGeneralResponse(String message, String language) {
    if (language == 'ur') {
      return _urduTranslations['help'] ?? 'میں تعلیمی، فیس، اور اسکول سے متعلق سوالات میں آپ کی مدد کر سکتا ہوں۔';
    }
    
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('uniform')) {
      return _getRandomResponse(_knowledgeBase['uniform']!);
    } else if (lowerMessage.contains('holiday') || lowerMessage.contains('vacation')) {
      return _getRandomResponse(_knowledgeBase['holidays']!);
    } else if (lowerMessage.contains('transport') || lowerMessage.contains('bus')) {
      return _getRandomResponse(_knowledgeBase['transport']!);
    } else if (lowerMessage.contains('contact')) {
      return _getRandomResponse(_knowledgeBase['contact']!);
    } else {
      return _getRandomResponse(_knowledgeBase['help']!);
    }
  }

  String _getUrduResponse(String message) {
    // Simple Urdu keyword matching
    if (message.contains('نمبرات') || message.contains('گریڈ')) {
      return _urduTranslations['grades']!;
    } else if (message.contains('فیس')) {
      return _urduTranslations['fees']!;
    } else if (message.contains('حاضری')) {
      return _urduTranslations['attendance']!;
    } else {
      return _urduTranslations['help']!;
    }
  }

  String _getDefaultResponse(String language) {
    if (language == 'ur') {
      return 'معذرت، میں آپ کا سوال سمجھ نہیں سکا۔ کیا آپ اسے دوبارہ پوچھ سکتے ہیں؟';
    }
    
    final responses = [
      'I\'m not sure I understand. Could you please rephrase your question?',
      'I can help with grades, fees, attendance, and general school questions. What would you like to know?',
      'Sorry, I didn\'t catch that. Try asking about your grades, fees, or school schedule.',
    ];
    
    return responses[Random().nextInt(responses.length)];
  }

  String _getRandomResponse(List<String> responses) {
    return responses[Random().nextInt(responses.length)];
  }

  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<void> _storeMessage(String userId, ChatMessage message) async {
    try {
      final history = await getConversationHistory(userId);
      history.add(message);
      
      // Keep only recent messages
      if (history.length > maxConversationHistory) {
        history.removeRange(0, history.length - maxConversationHistory);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history.map((msg) => msg.toJson()).toList();
      await prefs.setString('${_conversationHistoryKey}_$userId', jsonEncode(historyJson));
    } catch (e) {
      debugPrint('Error storing message: $e');
    }
  }

  Future<Map<String, List<ChatMessage>>> _getAllConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_conversationHistoryKey));
      
      final conversations = <String, List<ChatMessage>>{};
      
      for (final key in keys) {
        final userId = key.replaceFirst('${_conversationHistoryKey}_', '');
        final historyData = prefs.getString(key);
        
        if (historyData != null) {
          final historyJson = jsonDecode(historyData) as List;
          conversations[userId] = historyJson.map((json) => ChatMessage.fromJson(json)).toList();
        }
      }
      
      return conversations;
    } catch (e) {
      debugPrint('Error getting all conversations: $e');
      return {};
    }
  }
}

// Data Models and Enums

enum ChatIntent {
  greeting,
  academic,
  fees,
  technical,
  general,
  urdu,
  error,
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;
  final double? confidence;
  final ChatIntent? intent;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.language,
    this.confidence,
    this.intent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'language': language,
      'confidence': confidence,
      'intent': intent?.toString(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      language: json['language'],
      confidence: json['confidence']?.toDouble(),
      intent: json['intent'] != null 
          ? ChatIntent.values.firstWhere(
              (i) => i.toString() == json['intent'],
              orElse: () => ChatIntent.general,
            )
          : null,
    );
  }
}

class ChatbotResponse {
  final String content;
  final double confidence;
  final ChatIntent intent;
  final List<String> suggestions;

  ChatbotResponse({
    required this.content,
    required this.confidence,
    required this.intent,
    required this.suggestions,
  });
}

class ChatbotPreferences {
  final String language;
  final bool enableNotifications;
  final bool enableSuggestions;
  final String responseStyle;

  ChatbotPreferences({
    required this.language,
    required this.enableNotifications,
    required this.enableSuggestions,
    required this.responseStyle,
  });

  factory ChatbotPreferences.defaultPreferences() {
    return ChatbotPreferences(
      language: 'en',
      enableNotifications: true,
      enableSuggestions: true,
      responseStyle: 'friendly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'enableNotifications': enableNotifications,
      'enableSuggestions': enableSuggestions,
      'responseStyle': responseStyle,
    };
  }

  factory ChatbotPreferences.fromJson(Map<String, dynamic> json) {
    return ChatbotPreferences(
      language: json['language'],
      enableNotifications: json['enableNotifications'],
      enableSuggestions: json['enableSuggestions'],
      responseStyle: json['responseStyle'],
    );
  }
}

class ChatbotAnalytics {
  final int totalMessages;
  final int userMessages;
  final int botMessages;
  final double averageConfidence;
  final Map<ChatIntent, int> intentBreakdown;
  final Map<String, int> commonQueries;
  final DateRange period;

  ChatbotAnalytics({
    required this.totalMessages,
    required this.userMessages,
    required this.botMessages,
    required this.averageConfidence,
    required this.intentBreakdown,
    required this.commonQueries,
    required this.period,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}
