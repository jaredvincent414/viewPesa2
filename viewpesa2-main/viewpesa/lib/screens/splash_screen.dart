import 'package:flutter/material.dart';
import '../services/sms_reader.dart';
import 'package:viewpesa/database/dbhelper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progressValue = 0.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final smsReader = SmsReader();
    final dbHelper = DBHelper();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _progressValue = 0.3);
    await dbHelper.database;

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _progressValue = 0.6);

    try {
      bool permissionsGranted = await smsReader.requestSmsPermissions();
      if (permissionsGranted) {
        await smsReader.initSmsListener(); // No callback needed
        await smsReader.readMpesaTransactions();
      } else {
        print('SMS permissions not granted during splash screen');
      }
    } catch (e) {
      print('Error during SMS import: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _progressValue = 1.0);

    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent[700],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'VIEWPESA',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Transactions...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.white.withValues(),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE30613)),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}