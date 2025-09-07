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
    // University of Cyprus
    final ucy = UniversityModel(
      id: 'ucy',
      name: 'University of Cyprus',
      description: 'The University of Cyprus (UCY) is a public university established in 1989. It is the oldest and largest university in Cyprus, located in the capital city of Nicosia. UCY offers a wide range of undergraduate and postgraduate programs across various disciplines.',
      logoUrl: 'https://example.com/ucy_logo.png',
      websiteUrl: 'https://www.ucy.ac.cy/',
      location: 'Nicosia, Cyprus',
      latitude: 35.1589,
      longitude: 33.3780,
      foundedYear: 1989,
      studentCount: 7000,
      facultyCount: 600,
      rating: 4.5,
      reviewCount: 320,
      accreditations: ['AACSB', 'EQUIS', 'AMBA'],
      programs: [
        UniversityProgram(
          id: 'ucy_cs_bsc',
          name: 'Computer Science',
          description: 'Bachelor\'s degree in Computer Science covering programming, algorithms, data structures, and software engineering.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 3500,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: true,
          scholarshipAmount: 2000,
          scholarshipCriteria: 'Based on academic excellence',
        ),
        UniversityProgram(
          id: 'ucy_cs_msc',
          name: 'Computer Science',
          description: 'Master\'s degree in Computer Science with specializations in AI, cybersecurity, and data science.',
          level: ProgramLevel.master,
          durationMonths: 24,
          tuitionFeePerYear: 5000,
          currency: 'EUR',
          languages: ['English'],
          requirements: ['Bachelor\'s Degree', 'English Proficiency'],
          hasScholarship: true,
          scholarshipAmount: 3000,
          scholarshipCriteria: 'Based on academic excellence and research potential',
        ),
        UniversityProgram(
          id: 'ucy_business_bsc',
          name: 'Business Administration',
          description: 'Bachelor\'s degree in Business Administration covering management, marketing, finance, and entrepreneurship.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 3200,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: true,
          scholarshipAmount: 1800,
          scholarshipCriteria: 'Based on academic excellence',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Library',
          description: 'Modern library with over 500,000 books and digital resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Computer Labs',
          description: 'State-of-the-art computer labs with the latest software',
          icon: Icons.computer,
        ),
        UniversityFacility(
          name: 'Sports Center',
          description: 'Sports center with gym, swimming pool, and courts',
          icon: Icons.sports,
        ),
        UniversityFacility(
          name: 'Student Housing',
          description: 'On-campus housing for students',
          icon: Icons.home,
        ),
      ],
      rankings: {
        'QS World University Rankings': 651,
        'Times Higher Education': 601,
        'Shanghai Ranking': 701,
      },
      isPublic: true,
      virtualTourUrl: 'https://example.com/ucy_tour',
      photoUrls: [
        'https://example.com/ucy_photo1.jpg',
        'https://example.com/ucy_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/ucy_video.mp4',
      ],
      contactInfo: {
        'email': 'info@ucy.ac.cy',
        'phone': '+357 22 894000',
        'address': 'University House "Anastasios G. Leventis", P.O. Box 20537, 1678 Nicosia, Cyprus',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/UniversityOfCyprus',
        'twitter': 'https://twitter.com/UCYOfficial',
        'instagram': 'https://www.instagram.com/universityofcyprus',
      },
    );
    
    // Cyprus University of Technology
    final cut = UniversityModel(
      id: 'cut',
      name: 'Cyprus University of Technology',
      description: 'The Cyprus University of Technology (CUT) is a public university established in 2004. It is located in Limassol, the second-largest city in Cyprus. CUT focuses on applied research and technology-oriented programs.',
      logoUrl: 'https://example.com/cut_logo.png',
      websiteUrl: 'https://www.cut.ac.cy/',
      location: 'Limassol, Cyprus',
      latitude: 34.6757,
      longitude: 33.0450,
      foundedYear: 2004,
      studentCount: 3500,
      facultyCount: 250,
      rating: 4.3,
      reviewCount: 180,
      accreditations: ['AACSB', 'AMBA'],
      programs: [
        UniversityProgram(
          id: 'cut_eng_bsc',
          name: 'Electrical Engineering',
          description: 'Bachelor\'s degree in Electrical Engineering covering circuits, electronics, power systems, and telecommunications.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 3200,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: true,
          scholarshipAmount: 1500,
          scholarshipCriteria: 'Based on academic excellence',
        ),
        UniversityProgram(
          id: 'cut_nursing_bsc',
          name: 'Nursing',
          description: 'Bachelor\'s degree in Nursing covering healthcare, patient care, and medical procedures.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 3000,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: false,
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Library',
          description: 'Modern library with digital resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Engineering Labs',
          description: 'Well-equipped engineering laboratories',
          icon: Icons.science,
        ),
        UniversityFacility(
          name: 'Cafeteria',
          description: 'Student cafeteria with affordable meals',
          icon: Icons.restaurant,
        ),
      ],
      rankings: {
        'QS World University Rankings': 751,
        'Times Higher Education': 801,
      },
      isPublic: true,
      photoUrls: [
        'https://example.com/cut_photo1.jpg',
        'https://example.com/cut_photo2.jpg',
      ],
      videoUrls: [],
      contactInfo: {
        'email': 'info@cut.ac.cy',
        'phone': '+357 25 002500',
        'address': '30 Archbishop Kyprianou Str., 3036 Limassol, Cyprus',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/cutaccy',
        'twitter': 'https://twitter.com/CUT_ac_cy',
      },
    );
    
    // European University Cyprus
    final euc = UniversityModel(
      id: 'euc',
      name: 'European University Cyprus',
      description: 'European University Cyprus (EUC) is a private university established in 1961. It is located in Nicosia and offers a wide range of programs with a focus on business, health sciences, and humanities.',
      logoUrl: 'https://example.com/euc_logo.png',
      websiteUrl: 'https://www.euc.ac.cy/',
      location: 'Nicosia, Cyprus',
      latitude: 35.1674,
      longitude: 33.3623,
      foundedYear: 1961,
      studentCount: 5000,
      facultyCount: 300,
      rating: 4.2,
      reviewCount: 250,
      accreditations: ['AACSB', 'EQUIS'],
      programs: [
        UniversityProgram(
          id: 'euc_medicine_bsc',
          name: 'Medicine',
          description: 'Bachelor\'s degree in Medicine covering anatomy, physiology, pathology, and clinical practice.',
          level: ProgramLevel.bachelor,
          durationMonths: 72,
          tuitionFeePerYear: 18000,
          currency: 'EUR',
          languages: ['English'],
          requirements: ['High School Diploma', 'English Proficiency', 'Entrance Exam'],
          hasScholarship: true,
          scholarshipAmount: 5000,
          scholarshipCriteria: 'Based on academic excellence and entrance exam results',
        ),
        UniversityProgram(
          id: 'euc_business_mba',
          name: 'Business Administration (MBA)',
          description: 'Master\'s degree in Business Administration covering management, finance, marketing, and strategy.',
          level: ProgramLevel.master,
          durationMonths: 18,
          tuitionFeePerYear: 10000,
          currency: 'EUR',
          languages: ['English'],
          requirements: ['Bachelor\'s Degree', 'English Proficiency', 'Work Experience'],
          hasScholarship: true,
          scholarshipAmount: 3000,
          scholarshipCriteria: 'Based on academic excellence and work experience',
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Medical Simulation Center',
          description: 'State-of-the-art medical simulation center',
          icon: Icons.local_hospital,
        ),
        UniversityFacility(
          name: 'Library',
          description: 'Modern library with extensive resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Sports Center',
          description: 'Sports center with gym and courts',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 801,
        'Times Higher Education': 901,
      },
      isPublic: false,
      virtualTourUrl: 'https://example.com/euc_tour',
      photoUrls: [
        'https://example.com/euc_photo1.jpg',
        'https://example.com/euc_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/euc_video.mp4',
      ],
      contactInfo: {
        'email': 'info@euc.ac.cy',
        'phone': '+357 22 713000',
        'address': '6 Diogenes Street, Engomi, 2404 Nicosia, Cyprus',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/EuropeanUniversityCyprus',
        'instagram': 'https://www.instagram.com/europeanuniversitycyprus',
      },
    );
    
    // University of Nicosia
    final unic = UniversityModel(
      id: 'unic',
      name: 'University of Nicosia',
      description: 'The University of Nicosia (UNIC) is the largest private university in Cyprus, established in 1980. It is known for its business, law, and medical programs, as well as being a pioneer in blockchain education.',
      logoUrl: 'https://example.com/unic_logo.png',
      websiteUrl: 'https://www.unic.ac.cy/',
      location: 'Nicosia, Cyprus',
      latitude: 35.1674,
      longitude: 33.3623,
      foundedYear: 1980,
      studentCount: 12000,
      facultyCount: 550,
      rating: 4.4,
      reviewCount: 420,
      accreditations: ['AACSB', 'EQUIS', 'AMBA'],
      programs: [
        UniversityProgram(
          id: 'unic_medicine_bsc',
          name: 'Medicine',
          description: 'Bachelor\'s degree in Medicine in partnership with St George\'s, University of London.',
          level: ProgramLevel.bachelor,
          durationMonths: 72,
          tuitionFeePerYear: 30000,
          currency: 'EUR',
          languages: ['English'],
          requirements: ['High School Diploma', 'English Proficiency', 'Entrance Exam'],
          hasScholarship: true,
          scholarshipAmount: 10000,
          scholarshipCriteria: 'Based on academic excellence and entrance exam results',
        ),
        UniversityProgram(
          id: 'unic_blockchain_msc',
          name: 'Blockchain and Digital Currency',
          description: 'Master\'s degree in Blockchain and Digital Currency, the first of its kind in the world.',
          level: ProgramLevel.master,
          durationMonths: 18,
          tuitionFeePerYear: 12000,
          currency: 'EUR',
          languages: ['English'],
          requirements: ['Bachelor\'s Degree', 'English Proficiency'],
          hasScholarship: true,
          scholarshipAmount: 4000,
          scholarshipCriteria: 'Based on academic excellence',
        ),
        UniversityProgram(
          id: 'unic_law_llb',
          name: 'Law (LLB)',
          description: 'Bachelor\'s degree in Law covering civil law, criminal law, and international law.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 9500,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: false,
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Medical School',
          description: 'State-of-the-art medical school facilities',
          icon: Icons.local_hospital,
        ),
        UniversityFacility(
          name: 'Library',
          description: 'Extensive library with digital resources',
          icon: Icons.local_library,
        ),
        UniversityFacility(
          name: 'Student Housing',
          description: 'Modern student residences',
          icon: Icons.home,
        ),
        UniversityFacility(
          name: 'Sports Center',
          description: 'Comprehensive sports facilities',
          icon: Icons.sports,
        ),
      ],
      rankings: {
        'QS World University Rankings': 701,
        'Times Higher Education': 801,
      },
      isPublic: false,
      virtualTourUrl: 'https://example.com/unic_tour',
      photoUrls: [
        'https://example.com/unic_photo1.jpg',
        'https://example.com/unic_photo2.jpg',
      ],
      videoUrls: [
        'https://example.com/unic_video.mp4',
      ],
      contactInfo: {
        'email': 'info@unic.ac.cy',
        'phone': '+357 22 841500',
        'address': '46 Makedonitissas Avenue, 2417 Nicosia, Cyprus',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/UniversityofNicosia',
        'twitter': 'https://twitter.com/UniNicosia',
        'instagram': 'https://www.instagram.com/universityofnicosia',
      },
    );
    
    // Frederick University
    final frederick = UniversityModel(
      id: 'frederick',
      name: 'Frederick University',
      description: 'Frederick University is a private university established in 1965. It has campuses in both Nicosia and Limassol, offering programs in engineering, architecture, arts, and social sciences.',
      logoUrl: 'https://example.com/frederick_logo.png',
      websiteUrl: 'https://www.frederick.ac.cy/',
      location: 'Nicosia & Limassol, Cyprus',
      latitude: 35.1674,
      longitude: 33.3623,
      foundedYear: 1965,
      studentCount: 4000,
      facultyCount: 200,
      rating: 4.0,
      reviewCount: 150,
      accreditations: ['AACSB'],
      programs: [
        UniversityProgram(
          id: 'frederick_architecture_bsc',
          name: 'Architecture',
          description: 'Bachelor\'s degree in Architecture covering design, construction, and urban planning.',
          level: ProgramLevel.bachelor,
          durationMonths: 60,
          tuitionFeePerYear: 8500,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency', 'Portfolio'],
          hasScholarship: true,
          scholarshipAmount: 2500,
          scholarshipCriteria: 'Based on academic excellence and portfolio',
        ),
        UniversityProgram(
          id: 'frederick_engineering_bsc',
          name: 'Civil Engineering',
          description: 'Bachelor\'s degree in Civil Engineering covering structures, materials, and construction management.',
          level: ProgramLevel.bachelor,
          durationMonths: 48,
          tuitionFeePerYear: 7500,
          currency: 'EUR',
          languages: ['English', 'Greek'],
          requirements: ['High School Diploma', 'English Proficiency'],
          hasScholarship: false,
        ),
      ],
      facilities: [
        UniversityFacility(
          name: 'Architecture Studios',
          description: 'Well-equipped architecture design studios',
          icon: Icons.architecture,
        ),
        UniversityFacility(
          name: 'Engineering Labs',
          description: 'Modern engineering laboratories',
          icon: Icons.science,
        ),
        UniversityFacility(
          name: 'Library',
          description: 'Library with specialized resources',
          icon: Icons.local_library,
        ),
      ],
      rankings: {
        'QS World University Rankings': 901,
      },
      isPublic: false,
      photoUrls: [
        'https://example.com/frederick_photo1.jpg',
        'https://example.com/frederick_photo2.jpg',
      ],
      videoUrls: [],
      contactInfo: {
        'email': 'info@frederick.ac.cy',
        'phone': '+357 22 394394',
        'address': '7, Y. Frederickou Str., Pallouriotisa, 1036 Nicosia, Cyprus',
      },
      socialMedia: {
        'facebook': 'https://www.facebook.com/FrederickUniversity',
        'instagram': 'https://www.instagram.com/frederick_university',
      },
    );
    
    // Add universities to the map
    _universities['ucy'] = ucy;
    _universities['cut'] = cut;
    _universities['euc'] = euc;
    _universities['unic'] = unic;
    _universities['frederick'] = frederick;
    
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
