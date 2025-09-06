import 'package:flutter/material.dart';

/// Represents the type of chat message
enum MessageType {
  text,
  image,
  file,
  system
}

/// Represents the sender type
enum SenderType {
  user,
  support,
  system
}

/// Model for a chat message
class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final SenderType senderType;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.senderType,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.metadata,
  });

  /// Create a ChatMessageModel from a map
  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderType: _parseSenderType(map['senderType']),
      content: map['content'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      metadata: map['metadata'],
    );
  }

  /// Convert ChatMessageModel to a map
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType.toString().split('.').last,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'metadata': metadata,
    };
  }

  /// Create a copy of ChatMessageModel with some fields changed
  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    SenderType? senderType,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Parse SenderType from string
  static SenderType _parseSenderType(String? value) {
    if (value == null) return SenderType.user;
    
    switch (value.toLowerCase()) {
      case 'support':
        return SenderType.support;
      case 'system':
        return SenderType.system;
      case 'user':
      default:
        return SenderType.user;
    }
  }

  /// Parse MessageType from string
  static MessageType _parseMessageType(String? value) {
    if (value == null) return MessageType.text;
    
    switch (value.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}
