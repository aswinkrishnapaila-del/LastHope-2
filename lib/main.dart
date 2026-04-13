import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/app_state_provider.dart';
import 'core/services/background_service.dart';
import 'core/services/database_service.dart';
import 'dependency_injection.dart' as di;
import 'features/contacts/data/contact_service.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';
import 'features/medical/data/medical_service.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully");
  } catch (e) {
    debugPrint("⚠️  .env load failed (non-fatal): $e");
  }

  // CRITICAL: Supabase MUST initialize
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY',
    );
    debugPrint("✅ Supabase initialized successfully");
  } catch (e) {
    debugPrint("❌ CRITICAL: Supabase initialization failed: $e");

    // Show error and exit gracefully
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Supabase Initialization Failed',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please check:\n• .env file exists with valid keys\n• Internet connection\n• Supabase project configuration',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error: $e',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Exit main() to prevent further initialization
  }

  // Anonymous Auth - OPTIONAL (app continues if this fails)
  try {
    final response =
        await Supabase.instance.client.auth.signInAnonymously();
    debugPrint(
      "✅ Signed in anonymously: ${response.user?.id}",
    );
  } catch (e) {
    debugPrint("⚠️  Anonymous auth failed (app continues): $e");
  }

  // Initialize dependency injection
  try {
    await di.init();
  } catch (e) {
    debugPrint("DI initialization error: $e");
  }

  // Request permissions upfront (non-blocking)
  try {
    await _requestPermissions();
  } catch (e) {
    debugPrint("Permission request error (non-fatal): $e");
  }

  // Initialize Background Service (Phase 7)
  try {
    await initializeService();
  } catch (e) {
    debugPrint("Background service initialization error (non-fatal): $e");
  }

  // Initialize AppStateProvider and prime the cache
  AppStateProvider? appStateProvider;
  try {
    appStateProvider = AppStateProvider(
      db: DatabaseService(),
      medical: MedicalService(),
      contacts: ContactService(),
    );
    await appStateProvider.init();
    debugPrint('✅ AppStateProvider initialized');
  } catch (e) {
    debugPrint('⚠️ AppStateProvider init failed (non-fatal): $e');
    appStateProvider ??= AppStateProvider(
      db: DatabaseService(),
      medical: MedicalService(),
      contacts: ContactService(),
    );
  }

  runApp(LastHopeApp(appStateProvider: appStateProvider));
}

Future<void> _requestPermissions() async {
  if (kIsWeb) {
    // Web permissions are requested on demand usually (e.g. location, mic users gesture)
    return;
  }
  await [
    Permission.location,
    Permission.microphone,
    Permission.phone,
    Permission.sms,
    Permission.contacts,
  ].request();
}

class LastHopeApp extends StatelessWidget {
  final AppStateProvider appStateProvider;
  const LastHopeApp({super.key, required this.appStateProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateProvider>.value(
      value: appStateProvider,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: AppConstants.primaryRed,
          scaffoldBackgroundColor: AppConstants.backgroundBlack,
          textTheme: GoogleFonts.robotoTextTheme(
            Theme.of(context).textTheme.apply(
              bodyColor: AppConstants.textWhite,
              displayColor: AppConstants.textWhite,
            ),
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primaryRed,
            secondary: AppConstants.primaryRed,
            surface: Color(0xFF1E1E1E),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
