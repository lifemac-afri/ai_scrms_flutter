import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const AiScrmsApp(),
    ),
  );
}

class AiScrmsApp extends StatelessWidget {
  const AiScrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI-SCRMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await context.read<AuthProvider>().checkAuth();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏛️', style: TextStyle(fontSize: 56)),
              SizedBox(height: 20),
              Text('AI-SCRMS',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.teal)),
              SizedBox(height: 8),
              Text('Smart Campus Resource Management',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: AppTheme.teal),
            ],
          ),
        ),
      );
    }
    return context.watch<AuthProvider>().isLoggedIn
        ? const HomeScreen()
        : const AuthScreen();
  }
}
