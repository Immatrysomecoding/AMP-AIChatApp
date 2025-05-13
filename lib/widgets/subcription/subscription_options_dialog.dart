import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:aichat/core/services/iap_service.dart';

class SubscriptionOptionsDialog extends StatefulWidget {
  const SubscriptionOptionsDialog({super.key});

  @override
  State<SubscriptionOptionsDialog> createState() =>
      _SubscriptionOptionsDialogState();
}

class _SubscriptionOptionsDialogState extends State<SubscriptionOptionsDialog> {
  final IAPService _iapService = IAPService();
  bool _isLoading = false;
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (_iapService.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_iapService.products.isEmpty)
              const Text('No products available')
            else
              ..._iapService.products.map(
                (product) => _buildProductTile(product),
              ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      _isLoading || _selectedProductId == null
                          ? null
                          : _handlePurchase,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Subscribe'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(ProductDetails product) {
    final isSelected = _selectedProductId == product.id;
    final isYearly = product.id.contains('yearly');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProductId = product.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isYearly ? 'Yearly' : 'Monthly',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Save 17%',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  if (isYearly)
                    Text(
                      'Just ${_calculateMonthlyPrice(product.price)}/month',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateMonthlyPrice(String yearlyPrice) {
    // Extract number from price string and divide by 12
    final priceNum = double.tryParse(
      yearlyPrice.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (priceNum != null) {
      return '\$${(priceNum / 12).toStringAsFixed(2)}';
    }
    return yearlyPrice;
  }

  Future<void> _handlePurchase() async {
    if (_selectedProductId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = _iapService.products.firstWhere(
        (p) => p.id == _selectedProductId,
      );

      await _iapService.purchaseSubscription(product);

      // Close dialog on successful purchase initiation
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
