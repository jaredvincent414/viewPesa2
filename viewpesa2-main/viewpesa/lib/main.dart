import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/export.dart';
import 'screens/analytics.dart';
import 'screens/edittransaction.dart';
import 'screens/transactionpage.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ViewpesaApp(),
    ),
  );
}

class ViewpesaApp extends StatelessWidget {
  const ViewpesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'Viewpesa',
        theme: themeProvider.isDarkMode
            ? ThemeData.dark().copyWith(
          primaryColor: Colors.greenAccent[700],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[700],
              foregroundColor: Colors.white,
            ),
          ),
          cardTheme:  CardTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
        )
            : ThemeData(
          primaryColor: Colors.greenAccent[700],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[700],
              foregroundColor: Colors.white,
            ),
          ),
          cardTheme:CardTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
        ),
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterPage());
            case '/home':
              return MaterialPageRoute(
                builder: (_) =>  Home(),
                settings: settings,
              );
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ViewpesaProfile());
            case '/splash':
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/export':
              return MaterialPageRoute(builder: (_) => const ViewpesaExport());
            case '/analytics':
              return MaterialPageRoute(builder: (_) => const ViewpesaAnalysis());
            case '/transactions':
              return MaterialPageRoute(builder: (_) => const TransactionPage());
            case '/edit':
              return MaterialPageRoute(builder: (_) => const ViewpesaEdit());
            default:
              return MaterialPageRoute(builder: (_) => const LoginPage());
          }
        },
      ),
    );
  }
}