import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/ai_model_provider.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/models/AIModel.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // for signup
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _signUp() async {
    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First authenticate user
      bool success = await Provider.of<UserTokenProvider>(
        context,
        listen: false,
      ).signUp(_emailController.text, _passwordController.text);

      if (!success) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign-up failed. Please try again")),
          );
        }
        return;
      }

      // Get access token
      final accessToken =
          Provider.of<UserTokenProvider>(
            context,
            listen: false,
          ).user?.accessToken ??
          '';

      if (accessToken.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Invalid access token")));
        }
        return;
      }

      // Initialize AI models
      final aiModelProvider = Provider.of<AIModelProvider>(
        context,
        listen: false,
      );
      await aiModelProvider.fetchAvailableModels(accessToken);

      // Ensure a default model is selected (GPT-4o mini)
      final defaultModel = aiModelProvider.availableModels.firstWhere(
        (model) => model.id == 'gpt-4o-mini',
        orElse:
            () => aiModelProvider.availableModels.firstWhere(
              (model) => model.isDefault,
              orElse:
                  () =>
                      aiModelProvider.availableModels.isNotEmpty
                          ? aiModelProvider.availableModels.first
                          : AIModel(
                            id: 'gpt-4o-mini',
                            model: 'dify',
                            name: 'GPT-4o mini',
                            isDefault: true,
                          ),
            ),
      );

      // Set the default model in providers
      aiModelProvider.setSelectedModel(defaultModel);

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.setSelectedModel(defaultModel, accessToken);

      // Navigate to chat screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } catch (e) {
      print("Error during sign up process: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Left side - Welcome message and platform icons
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              color: Colors.blue[500],
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Jarvis',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),

                        // Welcome text
                        const Text(
                          'Welcome\nto Jarvis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Jarvis is here to streamline your online experience, let\'s get started!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),

                        const SizedBox(height: 60),

                        // Platform icons grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            children: [
                              _buildPlatformIcon(Icons.water), // Edge
                              _buildPlatformIcon(Icons.language), // Chrome
                              _buildPlatformIcon(Icons.apple), // Safari
                              _buildPlatformIcon(
                                Icons.desktop_windows,
                              ), // Windows
                              _buildPlatformIcon(Icons.smartphone), // Mobile
                              _buildPlatformIcon(
                                Icons.messenger_outline,
                              ), // Messenger
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right side - Signup form
                Container(
                  width: 400,
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Google sign up button
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Sign up with Google',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                      ),

                      const SizedBox(height: 30),

                      // Or continue with
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white38)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white38)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Email field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password field
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 30),

                      // Sign up button
                      ElevatedButton(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Sign Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _signUp,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Loading overlay (shown only when _isLoading is true)
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }
}
