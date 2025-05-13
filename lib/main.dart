import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens imports - all with lowercase 'screens'
import 'package:aichat/screens/home_page_screen.dart';
import 'package:aichat/screens/login_screen.dart';
import 'package:aichat/screens/signup_screen.dart';
import 'package:aichat/screens/chat_screen.dart';
import 'package:aichat/screens/bot_screen.dart';
import 'package:aichat/screens/chat_history_screen.dart';
import 'package:aichat/screens/knowledge_screen.dart';
import 'package:aichat/screens/email_screen.dart';
import 'package:aichat/screens/subscription_screen.dart';
import 'package:aichat/screens/ads_screen.dart';

// Providers
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/ai_model_provider.dart';
import 'package:aichat/core/providers/knowledge_provider.dart';

// Services
import 'package:aichat/core/services/subscription_state_manager.dart';

// Widgets
import 'package:aichat/widgets/Bot/update_bot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => SubscriptionStateManager()),
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
      themeMode: ThemeMode.light,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/chat': (context) => const ChatScreen(),
        '/bot': (context) => const BotScreen(),
        '/history': (context) => const ChatHistoryScreen(),
        '/knowledge': (context) => const KnowledgeScreen(),
        '/email': (context) => const EmailScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/ads': (context) => const AdsScreen(),
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
