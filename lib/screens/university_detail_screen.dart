import 'package:flutter/material.dart';
import '../models/university_model.dart';
import '../services/university_service.dart';
import '../theme/app_theme.dart';

class UniversityDetailScreen extends StatefulWidget {
  final String universityId;
  
  const UniversityDetailScreen({
    super.key,
    required this.universityId,
  });

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen> with SingleTickerProviderStateMixin {
  final UniversityService _universityService = UniversityService();
  bool _isLoading = true;
  UniversityModel? _university;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUniversity();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUniversity() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final university = await _universityService.getUniversity(widget.universityId);
      
      setState(() {
        _university = university;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading university: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _toggleFavorite() async {
    if (_university == null) return;
    
    try {
      final isFavorite = await _universityService.toggleFavorite(_university!.id);
      
      setState(() {
        _university = _university!.copyWith(isFavorite: isFavorite);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? '${_university!.name} added to favorites'
                  : '${_university!.name} removed from favorites',
            ),
            backgroundColor: isFavorite ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addToComparison() async {
    if (_university == null) return;
    
    try {
      final success = await _universityService.addToComparison(_university!.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_university!.name} added to comparison'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare up to 3 universities at a time'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_university?.name ?? 'University Details'),
        actions: [
          if (_university != null)
            IconButton(
              icon: Icon(
                _university!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _university!.isFavorite ? Colors.red : null,
              ),
              tooltip: _university!.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              onPressed: _toggleFavorite,
            ),
          if (_university != null)
            IconButton(
              icon: const Icon(Icons.compare),
              tooltip: 'Add to Comparison',
              onPressed: _addToComparison,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _university == null
              ? const Center(child: Text('University not found'))
              : Column(
                  children: [
                    // University header
                    _buildUniversityHeader(),
                    
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Programs'),
                        Tab(text: 'Facilities'),
                        Tab(text: 'Contact'),
                      ],
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryColor,
                    ),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildProgramsTab(),
                          _buildFacilitiesTab(),
                          _buildContactTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildUniversityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 30,
                child: Text(
                  _university!.name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _university!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _university!.location,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _university!.universityType,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Est. ${_university!.foundedYear}',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Students', _university!.studentCount.toString()),
              _buildStatCard('Faculty', _university!.facultyCount.toString()),
              _buildStatCard('Rating', '${_university!.rating} ★'),
              _buildStatCard('Programs', _university!.programs.length.toString()),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(_university!.description),
          const SizedBox(height: 24),
          
          const Text(
            'Rankings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._university!.rankings.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text(
                  '#${entry.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),
          
          const Text(
            'Accreditations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _university!.accreditations.map((accreditation) => Chip(
              label: Text(accreditation),
              backgroundColor: Colors.grey[200],
            )).toList(),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Tuition Fees',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Range: ${_university!.tuitionFeeRange}'),
          const SizedBox(height: 24),
          
          if (_university!.virtualTourUrl != null) ...[
            const Text(
              'Virtual Tour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app, this would open the virtual tour
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Virtual tour will be implemented in the next phase'),
                  ),
                );
              },
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Take Virtual Tour'),
            ),
            const SizedBox(height: 24),
          ],
          
          const Text(
            'Website',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // In a real app, this would open the website
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${_university!.websiteUrl}'),
                ),
              );
            },
            icon: const Icon(Icons.language),
            label: const Text('Visit Website'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgramsTab() {
    final bachelorPrograms = _university!.programs.where((p) => p.level == ProgramLevel.bachelor).toList();
    final masterPrograms = _university!.programs.where((p) => p.level == ProgramLevel.master).toList();
    final phdPrograms = _university!.programs.where((p) => p.level == ProgramLevel.phd).toList();
    final otherPrograms = _university!.programs.where((p) => 
      p.level != ProgramLevel.bachelor && 
      p.level != ProgramLevel.master && 
      p.level != ProgramLevel.phd
    ).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bachelorPrograms.isNotEmpty) ...[
            const Text(
              'Bachelor\'s Programs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...bachelorPrograms.map((program) => _buildProgramCard(program)),
            const SizedBox(height: 16),
          ],
          
          if (masterPrograms.isNotEmpty) ...[
            const Text(
              'Master\'s Programs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...masterPrograms.map((program) => _buildProgramCard(program)),
            const SizedBox(height: 16),
          ],
          
          if (phdPrograms.isNotEmpty) ...[
            const Text(
              'PhD Programs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...phdPrograms.map((program) => _buildProgramCard(program)),
            const SizedBox(height: 16),
          ],
          
          if (otherPrograms.isNotEmpty) ...[
            const Text(
              'Other Programs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...otherPrograms.map((program) => _buildProgramCard(program)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildProgramCard(UniversityProgram program) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          program.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(program.formattedLevel),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(program.description),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${program.formattedDuration}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Tuition: ${program.formattedTuitionFee}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    const Icon(Icons.language, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Languages: ${program.languages.join(", ")}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Requirements:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...program.requirements.map((requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(requirement)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                
                if (program.hasScholarship) ...[
                  const Text(
                    'Scholarship Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (program.scholarshipAmount != null)
                    Text('Amount: ${program.scholarshipAmount} ${program.currency}'),
                  if (program.scholarshipCriteria != null)
                    Text('Criteria: ${program.scholarshipCriteria}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFacilitiesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _university!.facilities.length,
      itemBuilder: (context, index) {
        final facility = _university!.facilities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              facility.icon,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            title: Text(
              facility.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(facility.description),
          ),
        );
      },
    );
  }
  
  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_university!.contactInfo['email'] != null)
                    ListTile(
                      leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                      title: const Text('Email'),
                      subtitle: Text(_university!.contactInfo['email']),
                    ),
                  
                  if (_university!.contactInfo['phone'] != null)
                    ListTile(
                      leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
                      title: const Text('Phone'),
                      subtitle: Text(_university!.contactInfo['phone']),
                    ),
                  
                  if (_university!.contactInfo['address'] != null)
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: const Text('Address'),
                      subtitle: Text(_university!.contactInfo['address']),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Social Media',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_university!.socialMedia['facebook'] != null)
                    ListTile(
                      leading: const Icon(Icons.facebook, color: Colors.blue),
                      title: const Text('Facebook'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // In a real app, this would open Facebook
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Facebook page'),
                          ),
                        );
                      },
                    ),
                  
                  if (_university!.socialMedia['twitter'] != null)
                    ListTile(
                      leading: const Icon(Icons.flutter_dash, color: Colors.lightBlue),
                      title: const Text('Twitter'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // In a real app, this would open Twitter
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Twitter page'),
                          ),
                        );
                      },
                    ),
                  
                  if (_university!.socialMedia['instagram'] != null)
                    ListTile(
                      leading: const Icon(Icons.camera_alt, color: Colors.purple),
                      title: const Text('Instagram'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // In a real app, this would open Instagram
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Instagram page'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
