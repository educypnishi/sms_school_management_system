import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/chart_card.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userRole;

  const AnalyticsDashboardScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  bool _isLoading = true;
  AnalyticsDashboard? _dashboard;
  TimePeriod _selectedPeriod = TimePeriod.month;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dashboard = await _analyticsService.getDashboardData(_selectedPeriod);
      
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _changePeriod(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }
  
  Widget _buildDashboard() {
    if (_dashboard == null) {
      return const Center(
        child: Text('No dashboard data available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          
          // Key metrics
          _buildKeyMetrics(),
          const SizedBox(height: 24),
          
          // Application charts
          _buildApplicationCharts(),
          const SizedBox(height: 24),
          
          // User charts
          _buildUserCharts(),
          const SizedBox(height: 24),
          
          // Program charts
          _buildProgramCharts(),
          const SizedBox(height: 24),
          
          // Last updated info
          Center(
            child: Text(
              'Last updated: ${_formatDateTime(_dashboard!.lastUpdated)}',
              style: const TextStyle(
                color: AppTheme.lightTextColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodButton(TimePeriod.day, 'Today'),
                  _buildPeriodButton(TimePeriod.week, 'This Week'),
                  _buildPeriodButton(TimePeriod.month, 'This Month'),
                  _buildPeriodButton(TimePeriod.quarter, 'This Quarter'),
                  _buildPeriodButton(TimePeriod.year, 'This Year'),
                  _buildPeriodButton(TimePeriod.all, 'All Time'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodButton(TimePeriod period, String label) {
    final isSelected = period == _selectedPeriod;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _changePeriod(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }
  
  Widget _buildKeyMetrics() {
    final metrics = _dashboard!.getKeyMetrics();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            return MetricCard(
              metric: metrics[index],
              onTap: () {
                // Show detailed view in the future
              },
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildApplicationCharts() {
    final stats = _dashboard!.applicationStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Application Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Application status distribution
        ChartCard(
          title: 'Application Status Distribution',
          subtitle: 'Total: ${stats.totalApplications} applications',
          chartWidget: SimplePieChart(
            dataPoints: [
              DataPoint(
                label: 'Pending',
                value: stats.pendingApplications.toDouble(),
                color: Colors.amber,
              ),
              DataPoint(
                label: 'Approved',
                value: stats.approvedApplications.toDouble(),
                color: Colors.green,
              ),
              DataPoint(
                label: 'Rejected',
                value: stats.rejectedApplications.toDouble(),
                color: Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Application trend
        ChartCard(
          title: 'Application Trend',
          subtitle: 'Number of applications over time',
          chartWidget: SimpleBarChart(
            dataPoints: stats.applicationTrend,
          ),
          height: 250,
        ),
        const SizedBox(height: 16),
        
        // Applications by university
        if (stats.applicationsByUniversity.isNotEmpty)
          ChartCard(
            title: 'Applications by University',
            chartWidget: SimpleBarChart(
              dataPoints: stats.applicationsByUniversity.entries
                  .map((e) => DataPoint(
                        label: e.key,
                        value: e.value.toDouble(),
                        color: _getColorForIndex(
                          stats.applicationsByUniversity.keys.toList().indexOf(e.key),
                        ),
                      ))
                  .toList(),
              barWidth: 40,
            ),
            height: 250,
          ),
      ],
    );
  }
  
  Widget _buildUserCharts() {
    final stats = _dashboard!.userStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // User distribution by role
        ChartCard(
          title: 'User Distribution by Role',
          subtitle: 'Total: ${stats.totalUsers} users',
          chartWidget: SimplePieChart(
            dataPoints: stats.usersByRole.entries
                .map((e) => DataPoint(
                      label: e.key.capitalize(),
                      value: e.value.toDouble(),
                      color: _getColorForRole(e.key),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // User growth trend
        ChartCard(
          title: 'User Growth Trend',
          subtitle: 'New user registrations over time',
          chartWidget: SimpleBarChart(
            dataPoints: stats.userGrowthTrend,
          ),
          height: 250,
        ),
      ],
    );
  }
  
  Widget _buildProgramCharts() {
    final stats = _dashboard!.programStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Program Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Programs by degree type
        ChartCard(
          title: 'Programs by Degree Type',
          subtitle: 'Total: ${stats.totalPrograms} programs',
          chartWidget: SimplePieChart(
            dataPoints: stats.programsByDegreeType.entries
                .map((e) => DataPoint(
                      label: e.key,
                      value: e.value.toDouble(),
                      color: _getColorForIndex(
                        stats.programsByDegreeType.keys.toList().indexOf(e.key),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Popular programs
        ChartCard(
          title: 'Most Popular Programs',
          subtitle: 'Based on application count',
          chartWidget: SimpleBarChart(
            dataPoints: stats.popularPrograms,
            barWidth: 40,
          ),
          height: 250,
        ),
      ],
    );
  }
  
  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    
    return colors[index % colors.length];
  }
  
  Color _getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.blue;
      case 'partner':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Dashboard Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use the Analytics Dashboard:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Select different time periods to view data for specific timeframes'),
              Text('• View key metrics at the top of the dashboard'),
              Text('• Explore detailed charts for applications, users, and programs'),
              Text('• Tap on any chart or metric for more detailed information'),
              Text('• Use the refresh button to get the latest data'),
              SizedBox(height: 16),
              Text(
                'Available Time Periods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Today: Data from the current day'),
              Text('• This Week: Data from the past 7 days'),
              Text('• This Month: Data from the current month'),
              Text('• This Quarter: Data from the past 3 months'),
              Text('• This Year: Data from the past year'),
              Text('• All Time: All historical data'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
