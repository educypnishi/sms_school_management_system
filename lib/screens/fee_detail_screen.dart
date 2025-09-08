import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../models/payment_model.dart';
import '../services/fee_service.dart';
import '../services/receipt_service.dart';
import '../theme/app_theme.dart';
import 'fee_payment_screen.dart';

class FeeDetailScreen extends StatefulWidget {
  final String feeId;

  const FeeDetailScreen({
    super.key,
    required this.feeId,
  });

  @override
  State<FeeDetailScreen> createState() => _FeeDetailScreenState();
}

class _FeeDetailScreenState extends State<FeeDetailScreen> {
  final FeeService _feeService = FeeService();
  final ReceiptService _receiptService = ReceiptService();
  bool _isLoading = true;
  bool _isGeneratingReceipt = false;
  FeeModel? _fee;
  List<PaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadFeeDetails();
  }

  Future<void> _loadFeeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get fee details
      final fee = await _feeService.getFeeById(widget.feeId);
      
      if (fee == null) {
        throw Exception('Fee not found');
      }
      
      // Get payments for this fee
      final payments = await _feeService.getPaymentsForFee(widget.feeId);
      
      setState(() {
        _fee = fee;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading fee details: $e'),
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
        title: const Text('Fee Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fee == null
              ? const Center(child: Text('Fee not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fee Summary Card
                      _buildFeeSummaryCard(),
                      const SizedBox(height: 24),
                      
                      // Fee Details Card
                      _buildFeeDetailsCard(),
                      const SizedBox(height: 24),
                      
                      // Payment History
                      _buildPaymentHistorySection(),
                    ],
                  ),
                ),
      bottomNavigationBar: _fee != null && 
                          _fee!.remainingAmount > 0 && 
                          _fee!.status != PaymentStatus.paid && 
                          _fee!.status != PaymentStatus.waived && 
                          _fee!.status != PaymentStatus.refunded
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeePaymentScreen(
                          feeId: widget.feeId,
                        ),
                      ),
                    ).then((_) => _loadFeeDetails());
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Make Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFeeSummaryCard() {
    if (_fee == null) return const SizedBox.shrink();
    
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final Color statusColor = _getStatusColor(_fee!.status);
    final bool isPaid = _fee!.status == PaymentStatus.paid || 
                        _fee!.status == PaymentStatus.waived ||
                        _fee!.status == PaymentStatus.refunded;
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fee!.feeTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fee!.academicYear} - ${_fee!.term}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Status and Amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(_fee!.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(_fee!.amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Payment Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Progress',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(_fee!.amountPaid / _fee!.amount * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _fee!.amountPaid / _fee!.amount,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPaid ? Colors.green : AppTheme.primaryColor,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          
          // Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Paid
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(_fee!.amountPaid),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Discount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(_fee!.discount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Balance',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(_fee!.remainingAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fee!.remainingAmount > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDetailsCard() {
    if (_fee == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Fee Type
            _buildDetailRow(
              'Fee Type',
              _getFeeTypeText(_fee!.feeType),
            ),
            
            // Due Date
            _buildDetailRow(
              'Due Date',
              DateFormat('MMMM dd, yyyy').format(_fee!.dueDate),
              valueColor: _fee!.isOverdue && 
                         _fee!.status != PaymentStatus.paid && 
                         _fee!.status != PaymentStatus.waived && 
                         _fee!.status != PaymentStatus.refunded
                  ? Colors.red
                  : null,
            ),
            
            // Days Remaining/Overdue
            if (_fee!.status != PaymentStatus.paid && 
                _fee!.status != PaymentStatus.waived && 
                _fee!.status != PaymentStatus.refunded) {
              if (_fee!.isOverdue) {
                _buildDetailRow(
                  'Overdue',
                  '${_fee!.daysOverdue} days',
                  valueColor: Colors.red,
                );
              } else {
                _buildDetailRow(
                  'Days Remaining',
                  '${_fee!.daysRemaining} days',
                );
              }
            },
            
            // Recurring
            if (_fee!.isRecurring) {
              _buildDetailRow(
                'Recurring',
                'Yes (${_fee!.recurringFrequency ?? 'Not specified'})',
              );
            },
            
            // Description
            if (_fee!.description != null && _fee!.description!.isNotEmpty) {
              _buildDetailRow(
                'Description',
                _fee!.description!,
                isMultiLine: true,
              );
            },
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _payments.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No payment records found',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: _payments.map((payment) => _buildPaymentCard(payment)).toList(),
              ),
      ],
    );
  }

  Future<void> _generateReceipt(PaymentModel payment) async {
    setState(() {
      _isGeneratingReceipt = true;
    });
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating receipt...'),
            ],
          ),
        ),
      );
      
      // Generate receipt number
      final receiptNumber = _receiptService.generateReceiptNumber();
      
      // Generate receipt PDF
      final pdfBytes = await _receiptService.generateReceiptPdf(
        paymentId: payment.id,
        receiptNumber: receiptNumber,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show options dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Receipt Generated'),
            content: const Text('What would you like to do with the receipt?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _receiptService.saveReceiptPdf(
                    pdfBytes,
                    'receipt_${receiptNumber.replaceAll('-', '_')}.pdf',
                  );
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _receiptService.printReceipt(pdfBytes);
                },
                child: const Text('Print'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _receiptService.shareReceipt(
                    pdfBytes,
                    'receipt_${receiptNumber.replaceAll('-', '_')}.pdf',
                  );
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingReceipt = false;
      });
    }
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(payment.paymentDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(payment.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Payment Method
            _buildDetailRow(
              'Payment Method',
              _getPaymentMethodText(payment.method),
            ),
            
            // Transaction ID
            if (payment.transactionId != null && payment.transactionId!.isNotEmpty) {
              _buildDetailRow(
                'Transaction ID',
                payment.transactionId!,
              );
            },
            
            // Receipt Number
            if (payment.receiptNumber != null && payment.receiptNumber!.isNotEmpty) {
              _buildDetailRow(
                'Receipt Number',
                payment.receiptNumber!,
              );
            },
            
            // Verification Status
            _buildDetailRow(
              'Verification',
              payment.isVerified ? 'Verified' : 'Pending Verification',
              valueColor: payment.isVerified ? Colors.green : Colors.orange,
            ),
            
            // Notes
            if (payment.notes != null && payment.notes!.isNotEmpty) {
              _buildDetailRow(
                'Notes',
                payment.notes!,
                isMultiLine: true,
              );
            },
            
            // Receipt Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingReceipt ? null : () => _generateReceipt(payment),
                icon: const Icon(Icons.receipt_long),
                label: Text(_isGeneratingReceipt ? 'Generating...' : 'Generate Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
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

  String _getFeeTypeText(FeeType feeType) {
    switch (feeType) {
      case FeeType.tuition:
        return 'Tuition';
      case FeeType.registration:
        return 'Registration';
      case FeeType.examination:
        return 'Examination';
      case FeeType.library:
        return 'Library';
      case FeeType.laboratory:
        return 'Laboratory';
      case FeeType.transportation:
        return 'Transportation';
      case FeeType.hostel:
        return 'Hostel';
      case FeeType.uniform:
        return 'Uniform';
      case FeeType.books:
        return 'Books';
      case FeeType.activities:
        return 'Activities';
      case FeeType.other:
        return 'Other';
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.onlineBanking:
        return 'Online Banking';
      case PaymentMethod.mobilePayment:
        return 'Mobile Payment';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
