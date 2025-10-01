import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LearningManagementScreen extends StatefulWidget {
  const LearningManagementScreen({super.key});

  @override
  State<LearningManagementScreen> createState() => _LearningManagementScreenState();
}

class _LearningManagementScreenState extends State<LearningManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Content', icon: Icon(Icons.library_books)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'Library', icon: Icon(Icons.local_library)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentTab(),
          _buildAssignmentsTab(),
          _buildQuizzesTab(),
          _buildLibraryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContentDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Upload Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Upload Learning Content', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.video_library),
                          label: const Text('Upload Video'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Upload PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) {
              final contents = [
                {'title': 'Mathematics Chapter 1', 'type': 'PDF', 'subject': 'Mathematics'},
                {'title': 'Physics Lab Video', 'type': 'Video', 'subject': 'Physics'},
                {'title': 'Chemistry Notes', 'type': 'PDF', 'subject': 'Chemistry'},
                {'title': 'Biology Presentation', 'type': 'Slides', 'subject': 'Biology'},
                {'title': 'English Grammar', 'type': 'PDF', 'subject': 'English'},
                {'title': 'Urdu Poetry', 'type': 'Audio', 'subject': 'Urdu'},
                {'title': 'Islamic Studies', 'type': 'PDF', 'subject': 'Islamic Studies'},
                {'title': 'Computer Programming', 'type': 'Video', 'subject': 'Computer Science'},
              ];
              
              final content = contents[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getContentTypeColor(content['type']!),
                    child: Icon(_getContentTypeIcon(content['type']!), color: Colors.white),
                  ),
                  title: Text(content['title']!),
                  subtitle: Text('Subject: ${content['subject']} • Type: ${content['type']}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('View')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Create Assignment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateAssignmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create New Assignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Assignments List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) {
              final assignments = [
                {'title': 'Math Problem Set 1', 'subject': 'Mathematics', 'due': '2025-01-15', 'submissions': 28},
                {'title': 'Physics Lab Report', 'subject': 'Physics', 'due': '2025-01-18', 'submissions': 25},
                {'title': 'Chemistry Equations', 'subject': 'Chemistry', 'due': '2025-01-20', 'submissions': 30},
                {'title': 'Biology Diagram', 'subject': 'Biology', 'due': '2025-01-22', 'submissions': 27},
                {'title': 'English Essay', 'subject': 'English', 'due': '2025-01-25', 'submissions': 32},
                {'title': 'Urdu Translation', 'subject': 'Urdu', 'due': '2025-01-28', 'submissions': 29},
              ];
              
              final assignment = assignments[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text('${assignment['submissions']}', 
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(assignment['title']!),
                  subtitle: Text('${assignment['subject']} • Due: ${assignment['due']}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to assignment details
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Create Quiz Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateQuizDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create New Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quizzes List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final quizzes = [
                {'title': 'Math Quiz 1', 'subject': 'Mathematics', 'questions': 10, 'attempts': 32},
                {'title': 'Physics MCQs', 'subject': 'Physics', 'questions': 15, 'attempts': 28},
                {'title': 'Chemistry Test', 'subject': 'Chemistry', 'questions': 12, 'attempts': 30},
                {'title': 'Biology Quiz', 'subject': 'Biology', 'questions': 8, 'attempts': 25},
                {'title': 'English Grammar', 'subject': 'English', 'questions': 20, 'attempts': 35},
              ];
              
              final quiz = quizzes[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('${quiz['questions']}', 
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(quiz['title']!),
                  subtitle: Text('${quiz['subject']} • ${quiz['attempts']} attempts'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to quiz details
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search library resources...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Categories
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard('E-Books', Icons.menu_book, Colors.blue),
                _buildCategoryCard('Videos', Icons.play_circle, Colors.red),
                _buildCategoryCard('Audio', Icons.audiotrack, Colors.green),
                _buildCategoryCard('Documents', Icons.description, Colors.orange),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Library Resources
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              final resources = [
                {'title': 'Mathematics Textbook Grade 9', 'type': 'E-Book', 'author': 'Dr. Ahmad Ali'},
                {'title': 'Physics Experiments Video', 'type': 'Video', 'author': 'Prof. Zara Ahmed'},
                {'title': 'Chemistry Reference Guide', 'type': 'E-Book', 'author': 'Dr. Hassan Khan'},
                {'title': 'Biology Audio Lectures', 'type': 'Audio', 'author': 'Ms. Fatima Sheikh'},
                {'title': 'English Literature Collection', 'type': 'E-Book', 'author': 'Mr. Ali Raza'},
                {'title': 'Urdu Poetry Recitation', 'type': 'Audio', 'author': 'Ms. Sana Malik'},
                {'title': 'Islamic Studies Guide', 'type': 'Document', 'author': 'Maulana Abdul Rahman'},
                {'title': 'Computer Programming Tutorial', 'type': 'Video', 'author': 'Mr. Usman Shah'},
                {'title': 'Pakistan Studies Notes', 'type': 'Document', 'author': 'Dr. Ayesha Khan'},
                {'title': 'General Science Encyclopedia', 'type': 'E-Book', 'author': 'Multiple Authors'},
              ];
              
              final resource = resources[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getResourceTypeColor(resource['type']!),
                    child: Icon(_getResourceTypeIcon(resource['type']!), color: Colors.white),
                  ),
                  title: Text(resource['title']!),
                  subtitle: Text('${resource['type']} • Author: ${resource['author']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContentTypeColor(String type) {
    switch (type) {
      case 'PDF': return Colors.red;
      case 'Video': return Colors.blue;
      case 'Audio': return Colors.green;
      case 'Slides': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Video': return Icons.play_circle;
      case 'Audio': return Icons.audiotrack;
      case 'Slides': return Icons.slideshow;
      default: return Icons.description;
    }
  }

  Color _getResourceTypeColor(String type) {
    switch (type) {
      case 'E-Book': return Colors.blue;
      case 'Video': return Colors.red;
      case 'Audio': return Colors.green;
      case 'Document': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type) {
      case 'E-Book': return Icons.menu_book;
      case 'Video': return Icons.play_circle;
      case 'Audio': return Icons.audiotrack;
      case 'Document': return Icons.description;
      default: return Icons.file_copy;
    }
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Learning Content'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Content Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add Content'),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Assignment'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Assignment Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Quiz'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Number of Questions',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
