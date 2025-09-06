/// Represents the status of a conversation
enum ConversationStatus {
  active,
  closed,
  pending
}

/// Represents the type of conversation
enum ConversationType {
  support,
  general,
  application,
  program
}

class ConversationModel {
  final String id;
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final ConversationStatus status;
  final ConversationType type;
  final String? assignedSupportId;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageContent,
    this.lastMessageTime,
    this.status = ConversationStatus.active,
    this.type = ConversationType.general,
    this.assignedSupportId,
    this.unreadCount = 0,
  });

  // Create a ConversationModel from a map
  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      title: map['title'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      lastMessageContent: map['lastMessageContent'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.parse(map['lastMessageTime']) 
          : null,
      status: _parseConversationStatus(map['status']),
      type: _parseConversationType(map['type']),
      assignedSupportId: map['assignedSupportId'],
      unreadCount: map['unreadCount'] ?? 0,
    );
  }

  // Convert ConversationModel to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'assignedSupportId': assignedSupportId,
      'unreadCount': unreadCount,
    };
  }

  // Create a copy of ConversationModel with some fields changed
  ConversationModel copyWith({
    String? id,
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    ConversationStatus? status,
    ConversationType? type,
    String? assignedSupportId,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      status: status ?? this.status,
      type: type ?? this.type,
      assignedSupportId: assignedSupportId ?? this.assignedSupportId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
  
  /// Parse ConversationStatus from string
  static ConversationStatus _parseConversationStatus(String? value) {
    if (value == null) return ConversationStatus.active;
    
    switch (value.toLowerCase()) {
      case 'closed':
        return ConversationStatus.closed;
      case 'pending':
        return ConversationStatus.pending;
      case 'active':
      default:
        return ConversationStatus.active;
    }
  }
  
  /// Parse ConversationType from string
  static ConversationType _parseConversationType(String? value) {
    if (value == null) return ConversationType.general;
    
    switch (value.toLowerCase()) {
      case 'support':
        return ConversationType.support;
      case 'application':
        return ConversationType.application;
      case 'program':
        return ConversationType.program;
      case 'general':
      default:
        return ConversationType.general;
    }
  }
}
