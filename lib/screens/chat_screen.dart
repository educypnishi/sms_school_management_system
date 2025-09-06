import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String _userId = '';
  String _receiverId = '';
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      _userId = currentUser.id;
      
      // Get conversation to determine receiver ID
      final conversation = await _messagingService.getConversationById(widget.conversationId);
      if (conversation != null) {
        // Set receiver ID as the other participant
        _receiverId = conversation.participantIds.firstWhere(
          (id) => id != _userId,
          orElse: () => '',
        );
      }
      
      // Get messages
      final messages = await _messagingService.getConversationMessages(widget.conversationId);
      
      // Mark messages as read
      await _messagingService.markConversationAsRead(widget.conversationId, _userId);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading messages: $e',
    );
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty || _receiverId.isEmpty) {
      return;
    }
    
    try {
      // Clear input field
      _messageController.clear();
      
      // Send message
      final newMessage = await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _userId,
        receiverId: _receiverId,
        content: message,
      );
      
      // Add message to list
      setState(() {
        _messages.add(newMessage);
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error sending message: $e',
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _userId;
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF2F2F2),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send Button
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _sendMessage,
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          
          // Message Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message Content
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Timestamp
                Text(
                  _formatDateTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
