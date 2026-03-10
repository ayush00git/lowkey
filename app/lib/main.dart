import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/username_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasUsername = prefs.getString('username') != null;
  runApp(LowkeyApp(hasUsername: hasUsername));
}

class LowkeyApp extends StatelessWidget {
  final bool hasUsername;
  const LowkeyApp({super.key, required this.hasUsername});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lowkey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
      ),
      initialRoute: hasUsername ? '/chat' : '/',
      routes: {
        '/': (ctx) => const UsernameScreen(),
        '/chat': (ctx) => const ChatScreen(),
      },
    );
  }
}
