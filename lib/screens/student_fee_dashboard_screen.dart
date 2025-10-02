import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'fee_payment_screen.dart';
// import 'fee_detail_screen.dart'; // Temporarily disabled

class StudentFeeDashboardScreen extends StatefulWidget {
  final String studentId;

  const StudentFeeDashboardScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentFeeDashboardScreen> createState() => _StudentFeeDashboardScreenState();
}

class _StudentFeeDashboardScreenState extends State<StudentFeeDashboardScreen> with SingleTickerProviderStateMixin {
  final FeeService _feeService = FeeService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<FeeModel> _fees = [];
  List<FeeModel> _pendingFees = [];
  List<FeeModel> _paidFees = [];
  List<FeeModel> _overdueFees = [];
  double _totalDue = 0;
  double _totalPaid = 0;
  double _totalOverdue = 0;
  late TabController _tabController;
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFees();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _studentName = user.name ?? 'Student';
        });
      }
    } catch (e) {
      debugPrint('Error loading student info: $e');
    }
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, generate sample fees if needed
      await _feeService.generateSampleFees();
      
      // Get all fees for the student
      final fees = await _feeService.getFeesForStudent(widget.studentId);
      
      // Filter fees by status
      final pendingFees = fees.where((fee) => 
        fee.status == PaymentStatus.pending || 
        fee.status == PaymentStatus.partiallyPaid
      ).toList();
      
      final paidFees = fees.where((fee) => 
        fee.status == PaymentStatus.paid || 
        fee.status == PaymentStatus.waived ||
        fee.status == PaymentStatus.refunded
      ).toList();
      
      final overdueFees = fees.where((fee) => fee.isOverdue).toList();
      
      // Calculate totals
      double totalDue = 0;
      double totalPaid = 0;
      double totalOverdue = 0;
      
      for (final fee in fees) {
        totalDue += fee.remainingAmount;
        totalPaid += fee.amountPaid;
        
        if (fee.isOverdue) {
          totalOverdue += fee.remainingAmount;
        }
      }
      
      setState(() {
        _fees = fees;
        _pendingFees = pendingFees;
        _paidFees = paidFees;
        _overdueFees = overdueFees;
        _totalDue = totalDue;
        _totalPaid = totalPaid;
        _totalOverdue = totalOverdue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading fees: $e'),
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
        title: const Text('Fee Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
            Tab(text: 'Overdue'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFees,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                _buildSummarySection(),
                
                // Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending Fees Tab
                      _buildFeesList(_pendingFees, 'No pending fees'),
                      
                      // Paid Fees Tab
                      _buildFeesList(_paidFees, 'No paid fees'),
                      
                      // Overdue Fees Tab
                      _buildFeesList(_overdueFees, 'No overdue fees'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info
          Text(
            'Hello, $_studentName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary Cards
          Row(
            children: [
              // Total Due Card
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Due',
                  amount: _totalDue,
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              
              // Total Paid Card
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Paid',
                  amount: _totalPaid,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              
              // Total Overdue Card
              Expanded(
                child: _buildSummaryCard(
                  title: 'Overdue',
                  amount: _totalOverdue,
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amount > 0 ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesList(List<FeeModel> fees, String emptyMessage) {
    if (fees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return _buildFeeCard(fee);
      },
    );
  }

  Widget _buildFeeCard(FeeModel fee) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final Color statusColor = _getStatusColor(fee.status);
    final bool isPaid = fee.status == PaymentStatus.paid || 
                        fee.status == PaymentStatus.waived ||
                        fee.status == PaymentStatus.refunded;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee Details - Coming Soon!')),
          );
        },
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fee.feeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(fee.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fee Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount:'),
                      Text(
                        currencyFormat.format(fee.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid:'),
                      Text(
                        currencyFormat.format(fee.amountPaid),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fee.amountPaid > 0 ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  if (fee.discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          currencyFormat.format(fee.discount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance:'),
                      Text(
                        currencyFormat.format(fee.remainingAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fee.remainingAmount > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Due Date:'),
                      Text(
                        DateFormat('MMM dd, yyyy').format(fee.dueDate),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fee.isOverdue && !isPaid ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  
                  if (fee.isOverdue && !isPaid) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overdue:'),
                        Text(
                          '${fee.daysOverdue} days',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (!isPaid && fee.remainingAmount > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeePaymentScreen(
                                feeId: fee.id,
                              ),
                            ),
                          ).then((_) => _loadFees());
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Make Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partiallyPaid:
        return Colors.blue;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.waived:
        return Colors.purple;
      case PaymentStatus.refunded:
        return Colors.teal;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.waived:
        return 'Waived';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}
