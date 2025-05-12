import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/widgets/sidebar.dart';
import 'package:intl/intl.dart';
import 'package:aichat/core/services/subscription_service.dart';
import 'package:aichat/core/services/subscription_state_manager.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool showCheckout = false;
  bool isLoading = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserTokenProvider>(context);
    // Get the actual user email from the provider
    String userEmail = 'nguyenlamquocthinh2709@gmail.com'; // default email

    // Try to get email from user object if available
    if (userProvider.user != null) {
      // You might need to extract email from the user object
      // For now using default email
      userEmail = 'nguyenlamquocthinh2709@gmail.com';
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer:
          isMobile
              ? const Drawer(child: Sidebar(selectedItem: "Subscription"))
              : null,
      appBar:
          isMobile
              ? AppBar(
                title: const Text("Subscription"),
                backgroundColor: Colors.blue.shade50,
                iconTheme: const IconThemeData(color: Colors.blue),
                elevation: 0,
              )
              : null,
      body:
          showCheckout
              ? _buildCheckoutScreen()
              : _buildMainContent(userEmail, isMobile),
    );
  }

  Widget _buildMainContent(String userEmail, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildContent(userEmail); // Only content on small screen
        } else {
          return Row(
            children: [
              const Sidebar(selectedItem: "Subscription"),
              Expanded(child: _buildContent(userEmail)),
            ],
          );
        }
      },
    );
  }

  Widget _buildContent(String userEmail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Subscription',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 60),

            // Content container
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Your Account Section
                  _buildAccountSection(userEmail),
                  const SizedBox(height: 40),

                  // Plans section
                  const Text(
                    'Plans that grow with you',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Individual',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 40),

                  // Plan cards
                  Row(
                    children: [
                      Expanded(child: _buildFreeCard()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildProCard()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(String email) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),

            // Email Field
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Change Password Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Handle password change
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Center(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              color: Colors.blue.shade600,
              size: 40,
            ),
            const SizedBox(height: 20),
            const Text(
              'Free',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Text(
              'For personal use',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            const Text(
              '\$0',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Text(
              '/ month',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: null, // Disabled for free plan
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.grey.shade600,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Current plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),
            _buildFeatureItem('Limited usage per day', true),
            _buildFeatureItem('Access to basic AI models', true),
            _buildFeatureItem('Web search capability', true),
            _buildFeatureItem('Basic email assistance', true),
            _buildFeatureItem('Standard response time', true),
          ],
        ),
      ),
    );
  }

  Widget _buildProCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.blue.shade600, size: 40),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Text(
              'For productivity',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '\$10',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  ' / month billed annually',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showCheckout = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Get Pro plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Everything in Free, plus:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('Unlimited usage', true),
            _buildFeatureItem('Access to all AI models', true),
            _buildFeatureItem('Advanced web search', true),
            _buildFeatureItem('Priority response time', true),
            _buildFeatureItem('Advanced email features', true),
            _buildFeatureItem('Custom bot creation', true),
            _buildFeatureItem('Knowledge base access', true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            included ? Icons.check : Icons.close,
            color: included ? Colors.green.shade600 : Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color:
                    included ? const Color(0xFF374151) : Colors.grey.shade400,
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutScreen() {
    // Calculate next billing date (one month from now)
    final DateTime nextBillingDate = DateTime.now().add(
      const Duration(days: 30),
    );
    final String formattedDate = DateFormat('M/d/yyyy').format(nextBillingDate);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  showCheckout = false;
                });
              },
            ),
          ),

          // Main content
          Center(
            child: Container(
              width: 400,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              margin: const EdgeInsets.symmetric(vertical: 40),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order details
                    const Text(
                      'Order details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCheckoutRow('Pro plan', '\$10'),
                    _buildCheckoutRow('Unlimited usage', ''),

                    const SizedBox(height: 8),
                    _buildCheckoutRow(
                      'Adjustments',
                      '-\$1.84',
                      subtitle: 'Prorated credit for the remainder of Pro plan',
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF4B5563)),
                    const SizedBox(height: 16),

                    _buildCheckoutRow('Subtotal', '\$8.16'),
                    _buildCheckoutRow('Tax', '\$0'),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF4B5563)),
                    const SizedBox(height: 16),

                    _buildCheckoutRow(
                      'Total due today',
                      '\$8.16',
                      bold: true,
                      large: true,
                    ),

                    const SizedBox(height: 24),

                    // Auto renewal notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your subscription will auto renew on $formattedDate. You will be charged \$10 (plus applicable taxes).',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment method
                    const Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Link by Stripe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'link',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'By providing your payment information, you allow Jarvis to charge your card in the amount above now and monthly until you cancel in accordance with our Terms. You can cancel at any time.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),

                    const SizedBox(height: 24),

                    // Test button to verify functionality
                    OutlinedButton(
                      onPressed: () async {
                        print('Test button clicked!');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test button works!'),
                            backgroundColor: Colors.blue,
                          ),
                        );

                        // Test the service
                        final userProvider = Provider.of<UserTokenProvider>(
                          context,
                          listen: false,
                        );
                        final token = userProvider.user?.accessToken ?? '';
                        print('Token exists: ${token.isNotEmpty}');

                        if (token.isNotEmpty) {
                          try {
                            final tokenUsage = await _subscriptionService
                                .getTokenUsage(token);
                            print('Current token usage: $tokenUsage');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Token usage: ${tokenUsage?['availableTokens'] ?? 'Unknown'}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            print('Test error: $e');
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Test Connection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Main Subscribe button
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                print('Subscribe button pressed!'); // Debug log
                                _handleSubscription();
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLoading ? Colors.grey : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child:
                          isLoading
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Subscribe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutRow(
    String label,
    String value, {
    String? subtitle,
    bool bold = false,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: bold ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: large ? 16 : 14,
                  fontWeight:
                      bold || large ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: bold || large ? Colors.white : const Color(0xFF9CA3AF),
              fontSize: large ? 18 : 14,
              fontWeight: bold || large ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscription() async {
    print('Subscribe button clicked'); // Debug log

    setState(() {
      isLoading = true;
    });

    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final token = userProvider.user?.accessToken ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to subscribe')),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Simulate API call with a delay instead of actually calling the API
      await Future.delayed(const Duration(seconds: 2));

      // Mark the user as Pro in our local state manager
      SubscriptionStateManager().upgradeToPro();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Successfully upgraded to Pro! You now have unlimited usage.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to chat screen
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } catch (e) {
      print('Error in subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
