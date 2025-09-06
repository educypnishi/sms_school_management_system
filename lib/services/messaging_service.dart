import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class MessagingService {
  // Messaging prefix for SharedPreferences keys
  static const String _conversationPrefix = 'conversation_';
  static const String _messagePrefix = 'message_';
  
  final NotificationService _notificationService = NotificationService();
  
  // Get all conversations for current user
  Future<List<ConversationModel>> getUserConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Check if we have any conversations stored
      final conversationsJson = prefs.getString('${_conversationPrefix}${currentUser.id}_list');
      
      // If no conversations exist, create sample conversations
      if (conversationsJson == null) {
        await _createSampleConversations(currentUser);
      }
      
      // Get all conversation IDs for current user
      final conversationIds = prefs.getStringList('${_conversationPrefix}${currentUser.id}_list') ?? [];
      
      // Get conversations
      final conversations = <ConversationModel>[];
      for (final id in conversationIds) {
        final conversation = await getConversationById(id);
        if (conversation != null && conversation.participantIds.contains(currentUser.id)) {
          conversations.add(conversation);
        }
      }
      
      // Sort by last message time (newest first)
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt;
        final bTime = b.lastMessageTime ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      
      return conversations;
    } catch (e) {
      debugPrint('Error getting user conversations: $e');
      return [];
    }
  }
  
  // Get conversation by ID
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
    required String title,
    required List<String> participantIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new conversation ID
      final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create conversation model
      final conversation = ConversationModel(
        id: conversationId,
        title: title,
        participantIds: participantIds,
        createdAt: DateTime.now(),
      );
      
      // Save conversation to SharedPreferences
      await prefs.setString('${_conversationPrefix}$conversationId', jsonEncode(conversation.toMap()));
      
      // Add conversation ID to each participant's conversation list
      for (final userId in participantIds) {
        final userConversationIds = prefs.getStringList('${_conversationPrefix}${userId}_list') ?? [];
        if (!userConversationIds.contains(conversationId)) {
          userConversationIds.add(conversationId);
          await prefs.setStringList('${_conversationPrefix}${userId}_list', userConversationIds);
        }
      }
      
      return conversation;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }
  
  // Get messages for a conversation
  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all message IDs for conversation
      final messageIds = prefs.getStringList('${_conversationPrefix}${conversationId}_messages') ?? [];
      
      // Get messages
      final messages = <MessageModel>[];
      for (final id in messageIds) {
        final message = await getMessageById(id);
        if (message != null) {
          messages.add(message);
        }
      }
      
      // Sort by creation date (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return messages;
    } catch (e) {
      debugPrint('Error getting conversation messages: $e');
      return [];
    }
  }
  
  // Get message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get message from SharedPreferences
      final messageJson = prefs.getString('${_messagePrefix}$messageId');
      if (messageJson == null) {
        return null;
      }
      
      // Parse message
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      return MessageModel.fromMap(messageMap, messageId);
    } catch (e) {
      debugPrint('Error getting message: $e');
      return null;
    }
  }
  
  // Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new message ID
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create message model
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      // Save message to SharedPreferences
      await prefs.setString('${_messagePrefix}$messageId', jsonEncode(message.toMap()));
      
      // Add message ID to conversation's message list
      final conversationMessageIds = prefs.getStringList('${_conversationPrefix}${conversationId}_messages') ?? [];
      conversationMessageIds.add(messageId);
      await prefs.setStringList('${_conversationPrefix}${conversationId}_messages', conversationMessageIds);
      
      // Update conversation with last message info
      final conversation = await getConversationById(conversationId);
      if (conversation != null) {
        final updatedConversation = conversation.copyWith(
          lastMessageContent: content,
          lastMessageTime: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await prefs.setString('${_conversationPrefix}$conversationId', jsonEncode(updatedConversation.toMap()));
      }
      
      // Create notification for receiver
      await _notificationService.createNotification(
        userId: receiverId,
        title: 'New Message',
        message: 'You have received a new message',
        type: NotificationService.typeMessage,
        data: {
          'conversationId': conversationId,
        },
      );
      
      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  // Mark message as read
  Future<MessageModel> markMessageAsRead(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get message from SharedPreferences
      final messageJson = prefs.getString('${_messagePrefix}$messageId');
      if (messageJson == null) {
        throw Exception('Message not found');
      }
      
      // Parse message
      final messageMap = jsonDecode(messageJson) as Map<String, dynamic>;
      final message = MessageModel.fromMap(messageMap, messageId);
      
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
  
  // Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      final messages = await getConversationMessages(conversationId);
      
      for (final message in messages) {
        if (message.receiverId == userId && !message.isRead) {
          await markMessageAsRead(message.id);
        }
      }
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      rethrow;
    }
  }
  
  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final conversations = await getUserConversations();
      int unreadCount = 0;
      
      for (final conversation in conversations) {
        final messages = await getConversationMessages(conversation.id);
        unreadCount += messages.where((m) => m.receiverId == userId && !m.isRead).length;
      }
      
      return unreadCount;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }
  
  // Create sample conversations for testing
  Future<void> _createSampleConversations(UserModel currentUser) async {
    try {
      // Create admin user
      final adminId = 'admin1';
      
      // Create conversation with admin
      final conversation = await createConversation(
        title: 'Support Chat',
        participantIds: [currentUser.id, adminId],
      );
      
      // Add welcome messages
      await sendMessage(
        conversationId: conversation.id,
        senderId: adminId,
        receiverId: currentUser.id,
        content: 'Welcome to EduCyp! How can we help you with your educational journey in Cyprus?',
      );
      
      await sendMessage(
        conversationId: conversation.id,
        senderId: adminId,
        receiverId: currentUser.id,
        content: 'Feel free to ask any questions about programs, applications, or the admission process.',
      );
    } catch (e) {
      debugPrint('Error creating sample conversations: $e');
    }
  }
}
