import 'package:aichat/Screens/email_screen.dart';
import 'package:aichat/Screens/knowledge_screen.dart';
import 'package:aichat/core/providers/knowledge_provider.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'screens/signup_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/bot_screen.dart';
import 'screens/chat_history_screen.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/ai_model_provider.dart';
import 'package:aichat/widgets/update_bot.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aichat/Screens/subscription_screen.dart';

Future<void> main() async {
  await dotenv.load(); // Load .env file
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserTokenProvider()),
        ChangeNotifierProvider(create: (_) => PromptProvider()),
        ChangeNotifierProvider(create: (_) => BotProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AIModelProvider()),
        ChangeNotifierProvider(create: (_) => KnowledgeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.light, // Thay đổi thành light mode
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/chat': (context) => const ChatScreen(),
        '/bot': (context) => const BotScreen(),
        '/history': (context) => const ChatHistoryScreen(),
        '/knowledge': (context) => const KnowledgeScreen(),
        '/email': (context) => const EmailScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/updateBot':
            (context) => UpdateBot(
              botId: '',
              initialName: '',
              initialDescription: '',
              initialInstructions: '',
              onBack: () {
                Navigator.pop(context);
              },
            ),
      },
    );
  }
}
