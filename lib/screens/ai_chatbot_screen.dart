import 'package:flutter/material.dart';
import '../services/ai_chatbot_service.dart';
import '../utils/enhanced_responsive_helper.dart';
import '../theme/app_theme.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final _chatbotService = AIChatbotService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (language) {
              setState(() {
                _selectedLanguage = language;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ur', child: Text('اردو')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: EnhancedResponsiveLayout(
        smallMobile: _buildMobileLayout(),
        mobile: _buildMobileLayout(),
        largeMobile: _buildTabletLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildMessagesList()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildMessagesList()),
              _buildInputArea(),
            ],
          ),
        ),
        Container(
          width: 1,
          color: Colors.grey[300],
        ),
        Expanded(
          flex: 1,
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSidebar(),
        ),
        Container(
          width: 1,
          color: Colors.grey[300],
        ),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(child: _buildMessagesList()),
              _buildInputArea(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: EnhancedResponsiveHelper.getEnhancedResponsivePadding(context),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            return _buildTypingIndicator();
          }
          
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: EnhancedResponsiveHelper.getEnhancedCardWidth(context) * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(
                  EnhancedResponsiveHelper.getEnhancedResponsiveValue(
                    context,
                    smallMobile: 12.0,
                    mobile: 16.0,
                    tablet: 20.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnhancedResponsiveText(
                    message.content,
                    baseFontSize: 14.0,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (!isUser && message.confidence != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(message.confidence!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(message.confidence! * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animationValue = ((value + delay) % 1.0);
        final opacity = (animationValue * 2).clamp(0.0, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EnhancedResponsiveHelper.getEnhancedResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _selectedLanguage == 'ur' 
                        ? 'اپنا سوال یہاں لکھیں...'
                        : 'Type your question here...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            'Check Grades',
            Icons.grade,
            () => _sendQuickMessage('What are my current grades?'),
          ),
          _buildQuickActionButton(
            'View Fees',
            Icons.payment,
            () => _sendQuickMessage('Show me my fee status'),
          ),
          _buildQuickActionButton(
            'Attendance',
            Icons.fact_check,
            () => _sendQuickMessage('What is my attendance percentage?'),
          ),
          _buildQuickActionButton(
            'Timetable',
            Icons.schedule,
            () => _sendQuickMessage('Show my class schedule'),
          ),
          _buildQuickActionButton(
            'Exams',
            Icons.quiz,
            () => _sendQuickMessage('When are my upcoming exams?'),
          ),
          const SizedBox(height: 24),
          Text(
            'Language',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('EN')),
              ButtonSegment(value: 'ur', label: Text('اردو')),
            ],
            selected: {_selectedLanguage},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedLanguage = selection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(title),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await _chatbotService.sendMessage(
        userId: 'current_user_123', // Replace with actual user ID
        message: text,
        language: _selectedLanguage,
      );

      setState(() {
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _loadConversationHistory() async {
    try {
      final history = await _chatbotService.getConversationHistory('current_user_123');
      setState(() {
        _messages = history;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading conversation history: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: _selectedLanguage == 'ur'
          ? 'السلام علیکم! میں آپ کا AI اسسٹنٹ ہوں۔ میں آپ کی تعلیمی، فیس، اور اسکول سے متعلق سوالات میں مدد کر سکتا ہوں۔'
          : 'Hello! I\'m your AI assistant for school-related queries. I can help you with grades, fees, attendance, and general school questions. How can I assist you today?',
      isUser: false,
      timestamp: DateTime.now(),
      language: _selectedLanguage,
      confidence: 1.0,
      intent: ChatIntent.greeting,
    );

    setState(() {
      if (_messages.isEmpty) {
        _messages.add(welcomeMessage);
      }
    });
  }

  void _clearConversation() async {
    try {
      await _chatbotService.clearConversationHistory('current_user_123');
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing conversation: $e')),
      );
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
