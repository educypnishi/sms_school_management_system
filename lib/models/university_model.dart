import 'package:flutter/material.dart';

/// Represents a university program level
enum ProgramLevel {
  bachelor,
  master,
  phd,
  certificate,
  diploma,
}

/// Represents a university program
class UniversityProgram {
  final String id;
  final String name;
  final String description;
  final ProgramLevel level;
  final int durationMonths;
  final double tuitionFeePerYear;
  final String currency;
  final List<String> languages;
  final List<String> requirements;
  final bool hasScholarship;
  final double? scholarshipAmount;
  final String? scholarshipCriteria;

  UniversityProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.durationMonths,
    required this.tuitionFeePerYear,
    required this.currency,
    required this.languages,
    required this.requirements,
    required this.hasScholarship,
    this.scholarshipAmount,
    this.scholarshipCriteria,
  });

  /// Get a formatted duration string
  String get formattedDuration {
    final years = (durationMonths / 12).floor();
    final months = durationMonths % 12;
    
    if (years > 0 && months > 0) {
      return '$years year${years > 1 ? 's' : ''} $months month${months > 1 ? 's' : ''}';
    } else if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }

  /// Get a formatted tuition fee string
  String get formattedTuitionFee {
    return '$tuitionFeePerYear $currency per year';
  }

  /// Get a formatted program level string
  String get formattedLevel {
    switch (level) {
      case ProgramLevel.bachelor:
        return 'Bachelor\'s Degree';
      case ProgramLevel.master:
        return 'Master\'s Degree';
      case ProgramLevel.phd:
        return 'PhD';
      case ProgramLevel.certificate:
        return 'Certificate';
      case ProgramLevel.diploma:
        return 'Diploma';
    }
  }

  /// Create a copy of this program with updated fields
  UniversityProgram copyWith({
    String? id,
    String? name,
    String? description,
    ProgramLevel? level,
    int? durationMonths,
    double? tuitionFeePerYear,
    String? currency,
    List<String>? languages,
    List<String>? requirements,
    bool? hasScholarship,
    double? scholarshipAmount,
    String? scholarshipCriteria,
  }) {
    return UniversityProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      durationMonths: durationMonths ?? this.durationMonths,
      tuitionFeePerYear: tuitionFeePerYear ?? this.tuitionFeePerYear,
      currency: currency ?? this.currency,
      languages: languages ?? this.languages,
      requirements: requirements ?? this.requirements,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      scholarshipAmount: scholarshipAmount ?? this.scholarshipAmount,
      scholarshipCriteria: scholarshipCriteria ?? this.scholarshipCriteria,
    );
  }

  /// Create a UniversityProgram from a map
  factory UniversityProgram.fromMap(Map<String, dynamic> map) {
    return UniversityProgram(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      level: _parseProgramLevel(map['level']),
      durationMonths: map['durationMonths'] ?? 0,
      tuitionFeePerYear: map['tuitionFeePerYear']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'EUR',
      languages: List<String>.from(map['languages'] ?? []),
      requirements: List<String>.from(map['requirements'] ?? []),
      hasScholarship: map['hasScholarship'] ?? false,
      scholarshipAmount: map['scholarshipAmount']?.toDouble(),
      scholarshipCriteria: map['scholarshipCriteria'],
    );
  }

  /// Convert UniversityProgram to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.toString().split('.').last,
      'durationMonths': durationMonths,
      'tuitionFeePerYear': tuitionFeePerYear,
      'currency': currency,
      'languages': languages,
      'requirements': requirements,
      'hasScholarship': hasScholarship,
      'scholarshipAmount': scholarshipAmount,
      'scholarshipCriteria': scholarshipCriteria,
    };
  }

  /// Parse ProgramLevel from string
  static ProgramLevel _parseProgramLevel(String? value) {
    if (value == null) return ProgramLevel.bachelor;
    
    switch (value.toLowerCase()) {
      case 'master':
        return ProgramLevel.master;
      case 'phd':
        return ProgramLevel.phd;
      case 'certificate':
        return ProgramLevel.certificate;
      case 'diploma':
        return ProgramLevel.diploma;
      case 'bachelor':
      default:
        return ProgramLevel.bachelor;
    }
  }
}

/// Represents a university facility
class UniversityFacility {
  final String name;
  final String description;
  final IconData icon;

  UniversityFacility({
    required this.name,
    required this.description,
    required this.icon,
  });

  /// Create a UniversityFacility from a map
  factory UniversityFacility.fromMap(Map<String, dynamic> map) {
    return UniversityFacility(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconForFacility(map['name'] ?? ''),
    );
  }

  /// Convert UniversityFacility to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  /// Get icon for facility based on name
  static IconData _getIconForFacility(String facilityName) {
    final name = facilityName.toLowerCase();
    
    if (name.contains('library')) return Icons.local_library;
    if (name.contains('lab')) return Icons.science;
    if (name.contains('sport')) return Icons.sports;
    if (name.contains('gym')) return Icons.fitness_center;
    if (name.contains('cafeteria') || name.contains('canteen')) return Icons.restaurant;
    if (name.contains('wifi')) return Icons.wifi;
    if (name.contains('parking')) return Icons.local_parking;
    if (name.contains('dorm') || name.contains('housing')) return Icons.home;
    if (name.contains('medical') || name.contains('health')) return Icons.local_hospital;
    if (name.contains('computer')) return Icons.computer;
    
    return Icons.school;
  }
}

/// Model for a university in the system
class UniversityModel {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String websiteUrl;
  final String location;
  final double latitude;
  final double longitude;
  final int foundedYear;
  final int studentCount;
  final int facultyCount;
  final double rating;
  final int reviewCount;
  final List<String> accreditations;
  final List<UniversityProgram> programs;
  final List<UniversityFacility> facilities;
  final Map<String, dynamic> rankings;
  final bool isPublic;
  final String? virtualTourUrl;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> socialMedia;
  final bool isFavorite;

  UniversityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.websiteUrl,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.foundedYear,
    required this.studentCount,
    required this.facultyCount,
    required this.rating,
    required this.reviewCount,
    required this.accreditations,
    required this.programs,
    required this.facilities,
    required this.rankings,
    required this.isPublic,
    this.virtualTourUrl,
    required this.photoUrls,
    required this.videoUrls,
    required this.contactInfo,
    required this.socialMedia,
    this.isFavorite = false,
  });

  /// Get the university type (public or private)
  String get universityType => isPublic ? 'Public' : 'Private';

  /// Get the student-to-faculty ratio
  double get studentFacultyRatio => facultyCount > 0 ? studentCount / facultyCount : 0;

  /// Get formatted student-to-faculty ratio
  String get formattedStudentFacultyRatio => facultyCount > 0 
      ? '${(studentCount / facultyCount).toStringAsFixed(1)}:1' 
      : 'N/A';

  /// Get the minimum tuition fee among all programs
  double get minTuitionFee {
    if (programs.isEmpty) return 0;
    return programs.map((p) => p.tuitionFeePerYear).reduce((a, b) => a < b ? a : b);
  }

  /// Get the maximum tuition fee among all programs
  double get maxTuitionFee {
    if (programs.isEmpty) return 0;
    return programs.map((p) => p.tuitionFeePerYear).reduce((a, b) => a > b ? a : b);
  }

  /// Get the tuition fee range as a string
  String get tuitionFeeRange {
    if (programs.isEmpty) return 'N/A';
    final currency = programs.first.currency;
    return '$minTuitionFee - $maxTuitionFee $currency per year';
  }

  /// Get the number of bachelor programs
  int get bachelorProgramCount => programs
      .where((p) => p.level == ProgramLevel.bachelor)
      .length;

  /// Get the number of master programs
  int get masterProgramCount => programs
      .where((p) => p.level == ProgramLevel.master)
      .length;

  /// Get the number of PhD programs
  int get phdProgramCount => programs
      .where((p) => p.level == ProgramLevel.phd)
      .length;

  /// Create a copy of this university with updated fields
  UniversityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? websiteUrl,
    String? location,
    double? latitude,
    double? longitude,
    int? foundedYear,
    int? studentCount,
    int? facultyCount,
    double? rating,
    int? reviewCount,
    List<String>? accreditations,
    List<UniversityProgram>? programs,
    List<UniversityFacility>? facilities,
    Map<String, dynamic>? rankings,
    bool? isPublic,
    String? virtualTourUrl,
    List<String>? photoUrls,
    List<String>? videoUrls,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? socialMedia,
    bool? isFavorite,
  }) {
    return UniversityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      foundedYear: foundedYear ?? this.foundedYear,
      studentCount: studentCount ?? this.studentCount,
      facultyCount: facultyCount ?? this.facultyCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      accreditations: accreditations ?? this.accreditations,
      programs: programs ?? this.programs,
      facilities: facilities ?? this.facilities,
      rankings: rankings ?? this.rankings,
      isPublic: isPublic ?? this.isPublic,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      contactInfo: contactInfo ?? this.contactInfo,
      socialMedia: socialMedia ?? this.socialMedia,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Create a UniversityModel from a map
  factory UniversityModel.fromMap(Map<String, dynamic> map) {
    // Parse programs
    final programsList = <UniversityProgram>[];
    if (map['programs'] != null) {
      for (final program in map['programs']) {
        programsList.add(UniversityProgram.fromMap(program));
      }
    }
    
    // Parse facilities
    final facilitiesList = <UniversityFacility>[];
    if (map['facilities'] != null) {
      for (final facility in map['facilities']) {
        facilitiesList.add(UniversityFacility.fromMap(facility));
      }
    }
    
    return UniversityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      websiteUrl: map['websiteUrl'] ?? '',
      location: map['location'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      foundedYear: map['foundedYear'] ?? 0,
      studentCount: map['studentCount'] ?? 0,
      facultyCount: map['facultyCount'] ?? 0,
      rating: map['rating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      accreditations: List<String>.from(map['accreditations'] ?? []),
      programs: programsList,
      facilities: facilitiesList,
      rankings: Map<String, dynamic>.from(map['rankings'] ?? {}),
      isPublic: map['isPublic'] ?? false,
      virtualTourUrl: map['virtualTourUrl'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      contactInfo: Map<String, dynamic>.from(map['contactInfo'] ?? {}),
      socialMedia: Map<String, dynamic>.from(map['socialMedia'] ?? {}),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  /// Convert UniversityModel to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'foundedYear': foundedYear,
      'studentCount': studentCount,
      'facultyCount': facultyCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'accreditations': accreditations,
      'programs': programs.map((p) => p.toMap()).toList(),
      'facilities': facilities.map((f) => f.toMap()).toList(),
      'rankings': rankings,
      'isPublic': isPublic,
      'virtualTourUrl': virtualTourUrl,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'contactInfo': contactInfo,
      'socialMedia': socialMedia,
      'isFavorite': isFavorite,
    };
  }
}
