import 'dart:convert';

class RoomModel {
  final String id;
  final String name;
  final String roomNumber;
  final String building;
  final String floor;
  final int capacity;
  final String type; // classroom, lab, auditorium, library, etc.
  final List<String> equipment; // projector, whiteboard, computers, etc.
  final bool isAvailable;
  final String? description;
  final Map<String, dynamic>? schedule; // occupied time slots
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.roomNumber,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    this.equipment = const [],
    this.isAvailable = true,
    this.description,
    this.schedule,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a RoomModel from a map (e.g., from Firestore)
  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      name: map['name'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      building: map['building'] ?? '',
      floor: map['floor'] ?? '',
      capacity: map['capacity'] ?? 0,
      type: map['type'] ?? 'classroom',
      equipment: map['equipment'] != null 
          ? List<String>.from(map['equipment']) 
          : [],
      isAvailable: map['isAvailable'] ?? true,
      description: map['description'],
      schedule: map['schedule'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Convert RoomModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'roomNumber': roomNumber,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'type': type,
      'equipment': equipment,
      'isAvailable': isAvailable,
      'description': description,
      'schedule': schedule,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toMap());
  }

  // Create from JSON string
  factory RoomModel.fromJsonString(String jsonString, String id) {
    return RoomModel.fromMap(jsonDecode(jsonString), id);
  }

  // Create a copy of RoomModel with some fields changed
  RoomModel copyWith({
    String? id,
    String? name,
    String? roomNumber,
    String? building,
    String? floor,
    int? capacity,
    String? type,
    List<String>? equipment,
    bool? isAvailable,
    String? description,
    Map<String, dynamic>? schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      equipment: equipment ?? this.equipment,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get fullName => '$building-$roomNumber ($name)';
  
  bool get isLab => type.toLowerCase().contains('lab');
  bool get isAuditorium => type.toLowerCase().contains('auditorium');
  bool get isLibrary => type.toLowerCase().contains('library');
  
  bool hasEquipment(String equipmentName) {
    return equipment.any((e) => e.toLowerCase().contains(equipmentName.toLowerCase()));
  }
  
  String get equipmentSummary {
    if (equipment.isEmpty) return 'No equipment listed';
    return equipment.join(', ');
  }
  
  // Check if room is suitable for a specific capacity
  bool canAccommodate(int requiredCapacity) {
    return capacity >= requiredCapacity;
  }
  
  // Get room utilization percentage (if schedule data is available)
  double get utilizationRate {
    if (schedule == null || schedule!.isEmpty) return 0.0;
    
    // Simple calculation based on occupied slots
    // In a real implementation, this would be more sophisticated
    final totalSlots = 40; // 5 days * 8 periods
    final occupiedSlots = schedule!.length;
    return (occupiedSlots / totalSlots) * 100;
  }
  
  // Get room status display
  String get statusDisplay {
    if (!isAvailable) return 'Unavailable';
    if (utilizationRate > 80) return 'Heavily Used';
    if (utilizationRate > 50) return 'Moderately Used';
    if (utilizationRate > 20) return 'Lightly Used';
    return 'Available';
  }
}
