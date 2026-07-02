import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'providers/form_provider.dart';
import 'providers/result_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/connectivity_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: API keys are in lib/config/app_keys.dart (gitignored)
  // For production, replace with --dart-define or a secure backend.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => FormProvider()),
      ],
      child: const FWUApp(),
    ),
  );
}

class FWUApp extends StatelessWidget {
  const FWUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FWU Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
