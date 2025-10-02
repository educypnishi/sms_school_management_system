import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String studentId;

  const PaymentGatewayScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.studentId,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  String _selectedPaymentMethod = 'JazzCash';
  bool _isProcessing = false;
  
  final List<Map<String, dynamic>> _pakistaniPaymentMethods = [
    {
      'name': 'JazzCash',
      'icon': Icons.phone_android,
      'description': 'Pay using JazzCash mobile wallet',
      'color': Colors.red,
    },
    {
      'name': 'EasyPaisa',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay using EasyPaisa mobile wallet',
      'color': Colors.green,
    },
    {
      'name': 'HBL Bank',
      'icon': Icons.account_balance,
      'description': 'Habib Bank Limited online banking',
      'color': Colors.blue,
    },
    {
      'name': 'UBL Bank',
      'icon': Icons.account_balance,
      'description': 'United Bank Limited online banking',
      'color': Colors.purple,
    },
    {
      'name': 'MCB Bank',
      'icon': Icons.account_balance,
      'description': 'Muslim Commercial Bank online banking',
      'color': Colors.orange,
    },
    {
      'name': 'Credit Card',
      'icon': Icons.credit_card,
      'description': 'Visa, MasterCard, or local bank cards',
      'color': Colors.indigo,
    },
    {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance_wallet,
      'description': 'Direct bank account transfer',
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Summary', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Description:'),
                        Expanded(
                          child: Text(
                            widget.description,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text(
                          'PKR ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Processing Fee:'),
                        Text('PKR ${(widget.amount * 0.025).toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          'PKR ${(widget.amount * 1.025).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // Payment Methods
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
            
                    // Payment Method Selection
                    const Text('Select Payment Method', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Pakistani Payment Methods
                    ..._pakistaniPaymentMethods.map((method) => _buildPaymentMethodCard(method)),
                    
                    _buildPaymentMethodTile(
                      'Credit Card',
                      Icons.credit_card,
                      'Visa, MasterCard, American Express',
                    ),
                    _buildPaymentMethodTile(
                      'Debit Card',
                      Icons.payment,
                      'Bank debit cards',
                    ),
                    _buildPaymentMethodTile(
                      'Bank Transfer',
                      Icons.account_balance,
                      'Direct bank transfer',
                    ),
                    _buildPaymentMethodTile(
                      'Mobile Banking',
                      Icons.phone_android,
                      'JazzCash, EasyPaisa, UBL Omni',
                    ),
                    _buildPaymentMethodTile(
                      'Online Banking',
                      Icons.computer,
                      'Internet banking',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment Form
            if (_selectedPaymentMethod == 'Credit Card' || _selectedPaymentMethod == 'Debit Card')
              _buildCardForm()
            else if (_selectedPaymentMethod == 'Bank Transfer')
              _buildBankTransferForm()
            else if (_selectedPaymentMethod == 'Mobile Banking')
              _buildMobileBankingForm()
            else if (_selectedPaymentMethod == 'Online Banking')
              _buildOnlineBankingForm(),
            
            const SizedBox(height: 24),
            
            // Security Notice
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Payment',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Your payment information is encrypted and secure. We do not store your card details.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Processing Payment...'),
                        ],
                      )
                    : Text('Pay PKR ${(widget.amount * 1.025).toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, IconData icon, String description) {
    return RadioListTile<String>(
      value: method,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
      title: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(method),
        ],
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildCardForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_selectedPaymentMethod} Details', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Transfer Details', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Bank',
                border: OutlineInputBorder(),
              ),
              items: [
                'Habib Bank Limited (HBL)',
                'United Bank Limited (UBL)',
                'MCB Bank',
                'Allied Bank',
                'Standard Chartered',
                'Faysal Bank',
              ].map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBankingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mobile Banking Details', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Service',
                border: OutlineInputBorder(),
              ),
              items: [
                'JazzCash',
                'EasyPaisa',
                'UBL Omni',
                'HBL Konnect',
                'Mobicash',
              ].map((service) => DropdownMenuItem(value: service, child: Text(service))).toList(),
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                hintText: '03XX XXXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBankingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Online Banking', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            const Text('You will be redirected to your bank\'s secure login page to complete the payment.'),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Your Bank',
                border: OutlineInputBorder(),
              ),
              items: [
                'Habib Bank Limited',
                'United Bank Limited',
                'MCB Bank',
                'Allied Bank',
                'Standard Chartered',
                'Faysal Bank',
                'Bank Alfalah',
                'Askari Bank',
              ].map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final bool isSelected = _selectedPaymentMethod == method['name'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['name'];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? method['color'] : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: method['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'],
                  color: method['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? method['color'] : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: method['color'],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() => _isProcessing = false);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: PKR ${(widget.amount * 1.025).toStringAsFixed(2)}'),
              Text('Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch}'),
              Text('Payment Method: $_selectedPaymentMethod'),
              const SizedBox(height: 16),
              const Text('A receipt has been sent to your registered email address.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Download Receipt'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}
