import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/auth_service.dart';

/// Service to manage chat conversations and messages
class ChatService {
  // Shared Preferences key prefixes
  static const String _conversationPrefix = 'conversation_';
  static const String _messagePrefix = 'message_';
  
  // Support agent IDs (for demo purposes)
  static const List<String> _supportAgentIds = ['support1', 'support2', 'support3'];
  
  // Get all conversations for a user
  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all conversation IDs for the user
      final conversationIds = prefs.getStringList('${_conversationPrefix}${userId}_list') ?? [];
      
      // If no conversations exist, create sample conversations
      if (conversationIds.isEmpty) {
        await _createSampleConversations(userId);
        return getUserConversations(userId);
      }
      
      // Get conversations
      final conversations = <ConversationModel>[];
      for (final id in conversationIds) {
        final conversation = await getConversationById(id);
        if (conversation != null) {
          conversations.add(conversation);
        }
      }
      
      // Sort by last message time (newest first)
      conversations.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) {
          return b.createdAt.compareTo(a.createdAt);
        } else if (a.lastMessageTime == null) {
          return 1;
        } else if (b.lastMessageTime == null) {
          return -1;
        } else {
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        }
      });
      
      return conversations;
    } catch (e) {
      debugPrint('Error getting user conversations: $e');
      return [];
    }
  }
  
  // Get a conversation by ID
  Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get conversation from SharedPreferences
      final conversationJson = prefs.getString('${_conversationPrefix}$conversationId');
      if (conversationJson == null) {
        return null;
      }
      
      // Parse conversation
      final conversationMap = jsonDecode(conversationJson) as Map<String, dynamic>;
      return ConversationModel.fromMap(conversationMap, conversationId);
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }
  
  // Create a new conversation
  Future<ConversationModel> createConversation({
    required String userId,
    required String title,
    required List<String> participantIds,
    ConversationType type = ConversationType.general,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new conversation ID
      final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Ensure the user is included in participants
      if (!participantIds.contains(userId)) {
        participantIds.add(userId);
      }
      
      // For support conversations, assign a support agent
      String? assignedSupportId;
      if (type == ConversationType.support) {
        assignedSupportId = _getRandomSupportAgent();
        if (!participantIds.contains(assignedSupportId)) {
          participantIds.add(assignedSupportId);
        }
      }
      
      // Create conversation model
      final conversation = ConversationModel(
        id: conversationId,
        title: title,
        participantIds: participantIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ConversationStatus.active,
        type: type,
        assignedSupportId: assignedSupportId,
      );
      
      // Save conversation to SharedPreferences
      await prefs.setString('${_conversationPrefix}$conversationId', jsonEncode(conversation.toMap()));
      
      // Add conversation ID to user's conversation list
      for (final participantId in participantIds) {
        final conversationIds = prefs.getStringList('${_conversationPrefix}${participantId}_list') ?? [];
        if (!conversationIds.contains(conversationId)) {
          conversationIds.add(conversationId);
          await prefs.setStringList('${_conversationPrefix}${participantId}_list', conversationIds);
        }
      }
      
      // Create a welcome message for support conversations
      if (type == ConversationType.support) {
        await sendMessage(
          conversationId: conversationId,
          senderId: assignedSupportId!,
          senderName: 'Support Agent',
          senderType: SenderType.support,
          content: 'Hello! How can I help you today?',
          type: MessageType.text,
        );
      }
      
      return conversation;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }
  
  // Update a conversation
  Future<ConversationModel> updateConversation(ConversationModel conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update conversation
      final updatedConversation = conversation.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Save updated conversation to SharedPreferences
      await prefs.setString('${_conversationPrefix}${conversation.id}', jsonEncode(updatedConversation.toMap()));
      
      return updatedConversation;
    } catch (e) {
      debugPrint('Error updating conversation: $e');
      rethrow;
    }
  }
  
  // Close a conversation
  Future<ConversationModel> closeConversation(String conversationId) async {
    try {
      final conversation = await getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }
      
      // Update conversation status
      final updatedConversation = conversation.copyWith(
        status: ConversationStatus.closed,
        updatedAt: DateTime.now(),
      );
      
      // Save updated conversation
      return updateConversation(updatedConversation);
    } catch (e) {
      debugPrint('Error closing conversation: $e');
      rethrow;
    }
  }
  
  // Get all messages for a conversation
  Future<List<ChatMessageModel>> getConversationMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all message IDs for the conversation
      final messageIds = prefs.getStringList('${_messagePrefix}${conversationId}_list') ?? [];
      
      // Get messages
      final messages = <ChatMessageModel>[];
      for (final id in messageIds) {
        final message = await getMessageById(id);
        if (message != null) {
          messages.add(message);
        }
      }
      
      // Sort by timestamp (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    } catch (e) {
      debugPrint('Error getting conversation messages: $e');
      return [];
    }
  }
  
  // Get a message by ID
  Future<ChatMessageModel?> getMessageById(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get message from SharedPreferences
      final messageJson = prefs.getString('${_messagePrefix}$messageId');
      if (messageJson == null) {
        return null;
      }
      
      // Parse message
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      return ChatMessageModel.fromMap(messageMap, messageId);
    } catch (e) {
      debugPrint('Error getting message: $e');
      return null;
    }
  }
  
  // Send a new message
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    String? senderName,
    required SenderType senderType,
    required String content,
    required MessageType type,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get conversation
      final conversation = await getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }
      
      // Generate a new message ID
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create message model
      final message = ChatMessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        attachmentUrl: attachmentUrl,
        metadata: metadata,
      );
      
      // Save message to SharedPreferences
      await prefs.setString('${_messagePrefix}$messageId', jsonEncode(message.toMap()));
      
      // Add message ID to conversation's message list
      final messageIds = prefs.getStringList('${_messagePrefix}${conversationId}_list') ?? [];
      messageIds.add(messageId);
      await prefs.setStringList('${_messagePrefix}${conversationId}_list', messageIds);
      
      // Update conversation with last message info
      final updatedConversation = conversation.copyWith(
        lastMessageContent: content,
        lastMessageTime: DateTime.now(),
        updatedAt: DateTime.now(),
        unreadCount: conversation.unreadCount + 1,
      );
      
      // Save updated conversation
      await updateConversation(updatedConversation);
      
      // If this is a user message to a support conversation, generate a response
      if (senderType == SenderType.user && conversation.type == ConversationType.support) {
        _generateSupportResponse(conversationId, content);
      }
      
      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  // Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      final conversation = await getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }
      
      // Update conversation with unread count = 0
      final updatedConversation = conversation.copyWith(
        unreadCount: 0,
      );
      
      // Save updated conversation
      await updateConversation(updatedConversation);
      
      // Get all messages for the conversation
      final messages = await getConversationMessages(conversationId);
      
      // Mark each unread message as read
      for (final message in messages) {
        if (!message.isRead && message.senderId != userId) {
          await _markMessageAsRead(message.id);
        }
      }
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      rethrow;
    }
  }
  
  // Mark a message as read
  Future<ChatMessageModel> _markMessageAsRead(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get message from SharedPreferences
      final messageJson = prefs.getString('${_messagePrefix}$messageId');
      if (messageJson == null) {
        throw Exception('Message not found');
      }
      
      // Parse message
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      final message = ChatMessageModel.fromMap(messageMap, messageId);
      
      // Update message
      final updatedMessage = message.copyWith(
        isRead: true,
      );
      
      // Save updated message to SharedPreferences
      await prefs.setString('${_messagePrefix}$messageId', jsonEncode(updatedMessage.toMap()));
      
      return updatedMessage;
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      rethrow;
    }
  }
  
  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      // Get all conversations for the user
      final conversations = await getUserConversations(userId);
      
      // Sum up unread counts
      return conversations.fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }
  
  // Generate a support response (for demo purposes)
  Future<void> _generateSupportResponse(String conversationId, String userMessage) async {
    // Simulate a delay for the response
    await Future.delayed(const Duration(seconds: 1));
    
    // Get conversation
    final conversation = await getConversationById(conversationId);
    if (conversation == null || conversation.assignedSupportId == null) {
      return;
    }
    
    // Generate a response based on the user's message
    String response;
    if (userMessage.toLowerCase().contains('hello') || 
        userMessage.toLowerCase().contains('hi') ||
        userMessage.toLowerCase().contains('hey')) {
      response = 'Hello! How can I assist you with your application to study in Cyprus?';
    } else if (userMessage.toLowerCase().contains('application') || 
               userMessage.toLowerCase().contains('apply')) {
      response = 'To apply for a program, you need to complete the application form and submit all required documents. Is there anything specific you need help with regarding your application?';
    } else if (userMessage.toLowerCase().contains('document') || 
               userMessage.toLowerCase().contains('upload')) {
      response = 'You can upload your documents in the Document Management section. Make sure all documents are clear and in PDF format. Do you need help with a specific document?';
    } else if (userMessage.toLowerCase().contains('program') || 
               userMessage.toLowerCase().contains('course')) {
      response = 'We offer various programs across different universities in Cyprus. You can browse and compare them in the Programs section. Are you looking for a specific field of study?';
    } else if (userMessage.toLowerCase().contains('deadline') || 
               userMessage.toLowerCase().contains('date')) {
      response = 'Application deadlines vary by program and university. You can check specific deadlines in the program details. Is there a particular program you are interested in?';
    } else if (userMessage.toLowerCase().contains('thank')) {
      response = 'You are welcome! If you have any other questions, feel free to ask. We are here to help!';
    } else {
      response = 'Thank you for your message. Our support team will review it and get back to you shortly. Is there anything else I can help you with in the meantime?';
    }
    
    // Send the response
    await sendMessage(
      conversationId: conversationId,
      senderId: conversation.assignedSupportId!,
      senderName: 'Support Agent',
      senderType: SenderType.support,
      content: response,
      type: MessageType.text,
    );
  }
  
  // Get a random support agent ID
  String _getRandomSupportAgent() {
    final random = DateTime.now().millisecondsSinceEpoch % _supportAgentIds.length;
    return _supportAgentIds[random];
  }
  
  // Create sample conversations for testing
  Future<void> _createSampleConversations(String userId) async {
    try {
      // Create a support conversation
      final supportConversation = await createConversation(
        userId: userId,
        title: 'Application Support',
        participantIds: [userId],
        type: ConversationType.support,
      );
      
      // Create a general conversation
      final generalConversation = await createConversation(
        userId: userId,
        title: 'General Information',
        participantIds: [userId, 'admin1'],
        type: ConversationType.general,
      );
      
      // Add sample messages to general conversation
      await sendMessage(
        conversationId: generalConversation.id,
        senderId: 'admin1',
        senderName: 'Admin',
        senderType: SenderType.support,
        content: 'Welcome to EduCyp! This is a general information channel where we will post important updates about studying in Cyprus.',
        type: MessageType.text,
      );
      
      await sendMessage(
        conversationId: generalConversation.id,
        senderId: 'admin1',
        senderName: 'Admin',
        senderType: SenderType.support,
        content: 'The application period for the Fall semester starts next month. Make sure to prepare your documents in advance!',
        type: MessageType.text,
      );
    } catch (e) {
      debugPrint('Error creating sample conversations: $e');
    }
  }
}
