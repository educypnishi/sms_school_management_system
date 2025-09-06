class ConversationModel {
  final String id;
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;

  ConversationModel({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageContent,
    this.lastMessageTime,
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
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
