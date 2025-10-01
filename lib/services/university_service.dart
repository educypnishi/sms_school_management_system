import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/university_model.dart';

/// Service to manage universities in the system
class UniversityService {
  // In a real app, this would be stored in Firebase or another database
  // For now, we'll use an in-memory map for demo purposes
  final Map<String, UniversityModel> _universities = {};
  
  // Shared Preferences keys
  static const String _universitiesKey = 'universities';
  static const String _favoriteUniversitiesKey = 'favorite_universities';
  static const String _comparisonListKey = 'comparison_list';
  
  /// Get all universities
  Future<List<UniversityModel>> getAllUniversities() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Generate sample data if needed
    if (_universities.isEmpty) {
      await generateSampleUniversities();
    }
    
    return _universities.values.toList();
  }
  
  /// Get a specific university by ID
  Future<UniversityModel?> getUniversity(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _universities[id];
  }
  
  /// Search universities by name, location, or program
  Future<List<UniversityModel>> searchUniversities(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (query.isEmpty) {
      return _universities.values.toList();
    }
    
    final queryLower = query.toLowerCase();
    
    return _universities.values.where((university) {
      // Search in name
      if (university.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      
      // Search in location
      if (university.location.toLowerCase().contains(queryLower)) {
        return true;
      }
      
      // Search in programs
      for (final program in university.programs) {
        if (program.name.toLowerCase().contains(queryLower)) {
          return true;
        }
      }
      
      return false;
    }).toList();
  }
  
  /// Filter universities by criteria
  Future<List<UniversityModel>> filterUniversities({
    bool? isPublic,
    ProgramLevel? programLevel,
    double? minTuition,
    double? maxTuition,
    double? minRating,
    bool? hasScholarship,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _universities.values.where((university) {
      // Filter by university type
      if (isPublic != null && university.isPublic != isPublic) {
        return false;
      }
      
      // Filter by program level
      if (programLevel != null) {
        final hasProgram = university.programs.any((p) => p.level == programLevel);
        if (!hasProgram) {
          return false;
        }
      }
      
      // Filter by tuition fee
      if (minTuition != null && university.minTuitionFee < minTuition) {
        return false;
      }
      if (maxTuition != null && university.maxTuitionFee > maxTuition) {
        return false;
      }
      
      // Filter by rating
      if (minRating != null && university.rating < minRating) {
        return false;
      }
      
      // Filter by scholarship availability
      if (hasScholarship != null) {
        final hasScholarshipProgram = university.programs.any((p) => p.hasScholarship);
        if (hasScholarshipProgram != hasScholarship) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  /// Get favorite universities
  Future<List<UniversityModel>> getFavoriteUniversities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoriteUniversitiesKey) ?? [];
      
      final favorites = <UniversityModel>[];
      for (final id in favoriteIds) {
        final university = _universities[id];
        if (university != null) {
          favorites.add(university.copyWith(isFavorite: true));
        }
      }
      
      return favorites;
    } catch (e) {
      debugPrint('Error getting favorite universities: $e');
      return [];
    }
  }
  
  /// Toggle university favorite status
  Future<bool> toggleFavorite(String universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoriteUniversitiesKey) ?? [];
      
      final university = _universities[universityId];
      if (university == null) {
        return false;
      }
      
      final isFavorite = favoriteIds.contains(universityId);
      
      if (isFavorite) {
        // Remove from favorites
        favoriteIds.remove(universityId);
        _universities[universityId] = university.copyWith(isFavorite: false);
      } else {
        // Add to favorites
        favoriteIds.add(universityId);
        _universities[universityId] = university.copyWith(isFavorite: true);
      }
      
      await prefs.setStringList(_favoriteUniversitiesKey, favoriteIds);
      
      return !isFavorite;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
  
  /// Get universities in comparison list
  Future<List<UniversityModel>> getComparisonList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparisonIds = prefs.getStringList(_comparisonListKey) ?? [];
      
      final comparisonList = <UniversityModel>[];
      for (final id in comparisonIds) {
        final university = _universities[id];
        if (university != null) {
          comparisonList.add(university);
        }
      }
      
      return comparisonList;
    } catch (e) {
      debugPrint('Error getting comparison list: $e');
      return [];
    }
  }
  
  /// Add university to comparison list
  Future<bool> addToComparison(String universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparisonIds = prefs.getStringList(_comparisonListKey) ?? [];
      
      // Check if already in comparison list
      if (comparisonIds.contains(universityId)) {
        return true;
      }
      
      // Check if comparison list is full (max 3 universities)
      if (comparisonIds.length >= 3) {
        return false;
      }
      
      // Add to comparison list
      comparisonIds.add(universityId);
      await prefs.setStringList(_comparisonListKey, comparisonIds);
      
      return true;
    } catch (e) {
      debugPrint('Error adding to comparison: $e');
      return false;
    }
  }
  
  /// Remove university from comparison list
  Future<bool> removeFromComparison(String universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparisonIds = prefs.getStringList(_comparisonListKey) ?? [];
      
      // Check if in comparison list
      if (!comparisonIds.contains(universityId)) {
        return true;
      }
      
      // Remove from comparison list
      comparisonIds.remove(universityId);
      await prefs.setStringList(_comparisonListKey, comparisonIds);
      
      return true;
    } catch (e) {
      debugPrint('Error removing from comparison: $e');
      return false;
    }
  }
  
  /// Clear comparison list
  Future<bool> clearComparisonList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_comparisonListKey, []);
      
      return true;
    } catch (e) {
      debugPrint('Error clearing comparison list: $e');
      return false;
    }
  }
  
  /// Save comparison result
  Future<bool> saveComparisonResult(String name, List<String> universityIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisons = prefs.getStringList('saved_comparisons') ?? [];
      
      // Create comparison data
      final comparisonData = {
        'name': name,
        'universities': universityIds,
        'date': DateTime.now().toIso8601String(),
      };
      
      // Add to saved comparisons
      savedComparisons.add(jsonEncode(comparisonData));
      await prefs.setStringList('saved_comparisons', savedComparisons);
      
      return true;
    } catch (e) {
      debugPrint('Error saving comparison result: $e');
      return false;
    }
  }
  
  /// Get saved comparison results
  Future<List<Map<String, dynamic>>> getSavedComparisons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisons = prefs.getStringList('saved_comparisons') ?? [];
      
      return savedComparisons.map((json) => 
        Map<String, dynamic>.from(jsonDecode(json))
      ).toList();
    } catch (e) {
      debugPrint('Error getting saved comparisons: $e');
      return [];
    }
  }
  
  /// Generate sample universities for demo purposes
  Future<void> generateSampleUniversities() async {
    // University of Karachi
    final uok = UniversityModel(
      id: 'uok',
      name: 'University of Karachi',
      description: 'The University of Karachi (UoK) is a public research university established in 1951. It is one of Pakistan\'s largest and oldest universities, located in Karachi, Sindh. UoK offers a wide range of undergraduate and postgraduate programs across various disciplines.',
      logoUrl: 'https://example.com/uok_logo.png',
      websiteUrl: 'https://www.uok.edu.pk/',
      location: 'Karachi, Sindh, Pakistan',
      latitude: 24.9456,
      longitude: 67.1300,
      foundedYear: 1951,
      studentCount: 24000,
      facultyCount: 1200,
      rating: 4.2,
      reviewCount: 450,
      accreditations: ['HEC Pakistan', 'QAA'],
      programs: [
        UniversityProgram(
          id: 'uok_cs_bsc',
          name: 'Computer Science',
          description: 'Bachelor\'s degree in Computer Science covering programming, algorithms, data structures, and software engineering.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 150000,
          currency: 'PKR',
          languages: ['English', 'Urdu'],
          requirements: ['Intermediate (FSc/FA)', 'Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 75000,
          scholarshipCriteria: 'Based on academic merit and need',
        ),
        UniversityProgram(
          id: 'uok_cs_msc',
          name: 'Computer Science',
          description: 'Master\'s degree in Computer Science with specializations in AI, cybersecurity, and data science.',
          level: ProgramLevel.master,
          durationMonths: 24,
          tuitionFeePerYear: 200000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Bachelor\'s Degree', 'Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 100000,
          scholarshipCriteria: 'Based on academic excellence and research potential',
        ),
        UniversityProgram(
          id: 'uok_business_bsc',
          name: 'Business Administration',
          description: 'Bachelor\'s degree in Business Administration covering management, marketing, finance, and entrepreneurship.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 120000,
          currency: 'PKR',
          languages: ['English', 'Urdu'],
          requirements: ['Intermediate (ICS/ICom)', 'Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 60000,
          scholarshipCriteria: 'Based on academic merit',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Dr. A.Q. Khan Library',
          description: 'Central library with over 800,000 books and digital resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Computer Labs',
          description: 'Modern computer labs with latest software and high-speed internet',
          icon: Icons.computer,
        ),
        UniversityFacility(
          name: 'Sports Complex',
          description: 'Sports complex with cricket ground, football field, and gymnasium',
          icon: Icons.sports,
        ),
        UniversityFacility(
          name: 'Hostels',
          description: 'Separate hostels for male and female students',
          icon: Icons.home,
        ),
      ],
      rankings: {
        'QS World University Rankings': 801,
        'Times Higher Education': 1001,
        'HEC Pakistan Ranking': 5,
      },
      isPublic: true,
      virtualTourUrl: 'https://example.com/uok_tour',
      photoUrls: [
        'https://example.com/uok_photo1.jpg',
        'https://example.com/uok_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/uok_video.mp4',
      ],
      contactInfo: {
        'email': 'info@uok.edu.pk',
        'phone': '+92 21 99261300',
        'address': 'University Road, Karachi-75270, Sindh, Pakistan',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/UniversityOfKarachi',
        'twitter': 'https://twitter.com/UoKOfficial',
        'instagram': 'https://www.instagram.com/universityofkarachi',
      },
    );
    
    // Lahore University of Management Sciences (LUMS)
    final lums = UniversityModel(
      id: 'lums',
      name: 'Lahore University of Management Sciences',
      description: 'LUMS is a private research university established in 1984. Located in Lahore, Punjab, it is one of Pakistan\'s most prestigious universities, known for its business, engineering, and social sciences programs.',
      logoUrl: 'https://example.com/lums_logo.png',
      websiteUrl: 'https://www.lums.edu.pk/',
      location: 'Lahore, Punjab, Pakistan',
      latitude: 31.4697,
      longitude: 74.4142,
      foundedYear: 1984,
      studentCount: 4500,
      facultyCount: 350,
      rating: 4.7,
      reviewCount: 280,
      accreditations: ['HEC Pakistan', 'AACSB', 'AMBA'],
      programs: [
        UniversityProgram(
          id: 'lums_eng_bsc',
          name: 'Electrical Engineering',
          description: 'Bachelor\'s degree in Electrical Engineering covering circuits, electronics, power systems, and telecommunications.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 800000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc Pre-Engineering)', 'SAT/Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 400000,
          scholarshipCriteria: 'Based on academic merit and financial need',
        ),
        UniversityProgram(
          id: 'lums_business_bsc',
          name: 'Business Administration',
          description: 'Bachelor\'s degree in Business Administration with focus on management, finance, and entrepreneurship.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 750000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (Any)', 'SAT/Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 375000,
          scholarshipCriteria: 'Based on academic excellence and need',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Suleman Dawood School of Business Library',
          description: 'World-class library with extensive digital and physical resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Engineering Labs',
          description: 'State-of-the-art engineering laboratories and research facilities',
          icon: Icons.science,
        ),
        UniversityFacility(
          name: 'Food Court',
          description: 'Modern food court with diverse dining options',
          icon: Icons.restaurant,
        ),
        UniversityFacility(
          name: 'Sports Complex',
          description: 'Complete sports facilities including cricket, football, and tennis',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 701,
        'Times Higher Education': 801,
        'HEC Pakistan Ranking': 2,
      },
      isPublic: false,
      photoUrls: [
        'https://example.com/lums_photo1.jpg',
        'https://example.com/lums_photo2.jpg',
      ],
      videoUrls: [],
      contactInfo: {
        'email': 'info@lums.edu.pk',
        'phone': '+92 42 3560 8000',
        'address': 'Opposite Sector U, DHA, Lahore Cantt., 54792, Pakistan',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/LUMSofficial',
        'twitter': 'https://twitter.com/LUMSofficial',
        'instagram': 'https://www.instagram.com/lumsofficial',
      },
    );
    
    // Aga Khan University
    final aku = UniversityModel(
      id: 'aku',
      name: 'Aga Khan University',
      description: 'Aga Khan University (AKU) is a private research university established in 1983. Located in Karachi, it is renowned for its medical, nursing, and education programs with international standards.',
      logoUrl: 'https://example.com/aku_logo.png',
      websiteUrl: 'https://www.aku.edu/',
      location: 'Karachi, Sindh, Pakistan',
      latitude: 24.8607,
      longitude: 67.0011,
      foundedYear: 1983,
      studentCount: 3000,
      facultyCount: 400,
      rating: 4.6,
      reviewCount: 200,
      accreditations: ['HEC Pakistan', 'LCME', 'WHO'],
      programs: [
        UniversityProgram(
          id: 'aku_medicine_bsc',
          name: 'Medicine (MBBS)',
          description: 'Bachelor of Medicine and Bachelor of Surgery covering anatomy, physiology, pathology, and clinical practice.',
          level: ProgramLevel.bachelor,
          durationMonths: 60,
          tuitionFeePerYear: 2500000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc Pre-Medical)', 'MCAT', 'Interview'],
          hasScholarship: true,
          scholarshipAmount: 1000000,
          scholarshipCriteria: 'Based on academic merit and financial need',
        ),
        UniversityProgram(
          id: 'aku_nursing_bsc',
          name: 'Nursing',
          description: 'Bachelor\'s degree in Nursing with focus on patient care, healthcare management, and clinical practice.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 800000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc Pre-Medical)', 'Entry Test', 'Interview'],
          hasScholarship: true,
          scholarshipAmount: 400000,
          scholarshipCriteria: 'Based on academic excellence and financial need',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Aga Khan University Hospital',
          description: 'World-class teaching hospital with advanced medical facilities',
          icon: Icons.local_hospital,
        ),
        UniversityFacility(
          name: 'Health Sciences Library',
          description: 'Specialized medical library with international resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Skills Lab',
          description: 'Medical simulation and skills training laboratory',
          icon: Icons.science,
        ),
        UniversityFacility(
          name: 'Student Center',
          description: 'Modern student center with recreational facilities',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 651,
        'Times Higher Education': 801,
        'HEC Pakistan Ranking': 3,
      },
      isPublic: false,
      virtualTourUrl: 'https://example.com/aku_tour',
      photoUrls: [
        'https://example.com/aku_photo1.jpg',
        'https://example.com/aku_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/aku_video.mp4',
      ],
      contactInfo: {
        'email': 'info@aku.edu',
        'phone': '+92 21 3486 4955',
        'address': 'Stadium Road, P.O. Box 3500, Karachi 74800, Pakistan',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/AgaKhanUniversity',
        'twitter': 'https://twitter.com/AKUniversity',
        'instagram': 'https://www.instagram.com/agakhanuniversity',
      },
    );
    
    // National University of Sciences and Technology (NUST)
    final nust = UniversityModel(
      id: 'nust',
      name: 'National University of Sciences and Technology',
      description: 'NUST is a public research university established in 1991. Located in Islamabad, it is one of Pakistan\'s leading engineering and technology universities with multiple campuses across the country.',
      logoUrl: 'https://example.com/nust_logo.png',
      websiteUrl: 'https://www.nust.edu.pk/',
      location: 'Islamabad, Pakistan',
      latitude: 33.6844,
      longitude: 73.0479,
      foundedYear: 1991,
      studentCount: 15000,
      facultyCount: 800,
      rating: 4.5,
      reviewCount: 380,
      accreditations: ['HEC Pakistan', 'PEC', 'ABET'],
      programs: [
        UniversityProgram(
          id: 'nust_cs_bsc',
          name: 'Computer Science',
          description: 'Bachelor\'s degree in Computer Science with focus on software engineering, AI, and cybersecurity.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 400000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc Pre-Engineering)', 'NET Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 200000,
          scholarshipCriteria: 'Based on NET test performance and financial need',
        ),
        UniversityProgram(
          id: 'nust_mech_bsc',
          name: 'Mechanical Engineering',
          description: 'Bachelor\'s degree in Mechanical Engineering covering thermodynamics, fluid mechanics, and design.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 350000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc Pre-Engineering)', 'NET Entry Test'],
          hasScholarship: true,
          scholarshipAmount: 175000,
          scholarshipCriteria: 'Based on academic merit',
        ),
        UniversityProgram(
          id: 'nust_mba',
          name: 'Business Administration (MBA)',
          description: 'Master\'s degree in Business Administration with specializations in finance, marketing, and management.',
          level: ProgramLevel.master,
          durationMonths: 24,
          tuitionFeePerYear: 500000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Bachelor\'s Degree', 'GAT General', 'Work Experience'],
          hasScholarship: true,
          scholarshipAmount: 250000,
          scholarshipCriteria: 'Based on GAT score and professional experience',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'NUST Central Library',
          description: 'Modern library with extensive engineering and technology resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Research Centers',
          description: 'Multiple research centers for advanced engineering studies',
          icon: Icons.science,
        ),
        UniversityFacility(
          name: 'Student Hostels',
          description: 'On-campus accommodation for male and female students',
          icon: Icons.home,
        ),
        UniversityFacility(
          name: 'Sports Complex',
          description: 'Complete sports facilities including cricket, football, and indoor games',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 401,
        'Times Higher Education': 601,
        'HEC Pakistan Ranking': 1,
      },
      isPublic: true,
      virtualTourUrl: 'https://example.com/nust_tour',
      photoUrls: [
        'https://example.com/nust_photo1.jpg',
        'https://example.com/nust_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/nust_video.mp4',
      ],
      contactInfo: {
        'email': 'info@nust.edu.pk',
        'phone': '+92 51 9085 5000',
        'address': 'H-12, Islamabad, 44000, Pakistan',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/nustpakistan',
        'twitter': 'https://twitter.com/nustpakistan',
        'instagram': 'https://www.instagram.com/nustpakistan',
      },
    );
    
    // Institute of Business Administration (IBA) Karachi
    final iba = UniversityModel(
      id: 'iba',
      name: 'Institute of Business Administration Karachi',
      description: 'IBA Karachi is a public business school established in 1955. It is one of Pakistan\'s oldest and most prestigious business schools, offering programs in business, computer science, and social sciences.',
      logoUrl: 'https://example.com/iba_logo.png',
      websiteUrl: 'https://www.iba.edu.pk/',
      location: 'Karachi, Sindh, Pakistan',
      latitude: 24.8607,
      longitude: 67.0011,
      foundedYear: 1955,
      studentCount: 6000,
      facultyCount: 300,
      rating: 4.4,
      reviewCount: 220,
      accreditations: ['HEC Pakistan', 'AACSB'],
      programs: [
        UniversityProgram(
          id: 'iba_bba',
          name: 'Business Administration (BBA)',
          description: 'Bachelor\'s degree in Business Administration with focus on management, finance, and marketing.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 300000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (Any)', 'IBA Admission Test'],
          hasScholarship: true,
          scholarshipAmount: 150000,
          scholarshipCriteria: 'Based on admission test performance and financial need',
        ),
        UniversityProgram(
          id: 'iba_cs_bsc',
          name: 'Computer Science',
          description: 'Bachelor\'s degree in Computer Science with emphasis on software development and data science.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 350000,
          currency: 'PKR',
          languages: ['English'],
          requirements: ['Intermediate (FSc/ICS)', 'IBA Admission Test'],
          hasScholarship: true,
          scholarshipAmount: 175000,
          scholarshipCriteria: 'Based on academic merit',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Aman CED',
          description: 'Center for Entrepreneurial Development with modern facilities',
          icon: Icons.business,
        ),
        UniversityFacility(
          name: 'Computer Labs',
          description: 'Advanced computer laboratories with latest technology',
          icon: Icons.computer,
        ),
        UniversityFacility(
          name: 'IBA Library',
          description: 'Comprehensive library with business and technology resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Sports Facilities',
          description: 'Cricket ground, basketball court, and gymnasium',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 651,
        'HEC Pakistan Ranking': 4,
      },
      isPublic: true,
      photoUrls: [
        'https://example.com/iba_photo1.jpg',
        'https://example.com/iba_photo2.jpg',
      ],
      videoUrls: [],
      contactInfo: {
        'email': 'info@iba.edu.pk',
        'phone': '+92 21 3810 4700',
        'address': 'University Road, Karachi-75270, Sindh, Pakistan',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/IBAKarachi',
        'twitter': 'https://twitter.com/IBAKarachi',
        'instagram': 'https://www.instagram.com/ibakarachi',
      },
    );
    
    // Add universities to the map
    _universities['uok'] = uok;
    _universities['lums'] = lums;
    _universities['aku'] = aku;
    _universities['nust'] = nust;
    _universities['iba'] = iba;
    
    // Load favorite universities
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoriteUniversitiesKey) ?? [];
      
      for (final id in favoriteIds) {
        final university = _universities[id];
        if (university != null) {
          _universities[id] = university.copyWith(isFavorite: true);
        }
      }
    } catch (e) {
      debugPrint('Error loading favorite universities: $e');
    }
  }
}
