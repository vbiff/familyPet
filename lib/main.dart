import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jhonny/core/config/app_config.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/core/services/notification_service.dart';
import 'package:jhonny/core/services/pet_mood_service.dart';
import 'package:jhonny/core/services/theme_service.dart' as theme_service;
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/home/presentation/pages/home_page.dart';
import 'package:jhonny/features/auth/presentation/pages/login_page.dart';
import 'package:jhonny/features/onboarding/presentation/pages/app_onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global services
final themeService = theme_service.ThemeService();
final notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeServices();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Initialize Supabase
    await AppConfig.load();

    // Initialize theme service
    await themeService.initialize();

    // Initialize pet mood service with hourly happiness decay
    try {
      PetMoodService().initialize();
      debugPrint('✅ Pet mood service initialized successfully');
    } catch (e) {
      debugPrint('❌ Pet mood service initialization failed: $e');
      // App continues to work without the mood service
    }

    // Initialize notification service
    try {
      await notificationService.initialize();
      await notificationService.requestPermissions();

      // Schedule default notifications
      await notificationService.scheduleDailyReminder(
          19, 0); // 7 PM daily reminder
      await notificationService.scheduleWeeklyReport();

      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Notification service initialization failed: $e');
      // App continues to work without notifications
    }
  } catch (error) {
    debugPrint('Error initializing services: $error');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<theme_service.ThemeMode>(
      stream: themeService.themeStream,
      initialData: themeService.currentThemeMode,
      builder: (context, themeSnapshot) {
        final themeMode = themeSnapshot.data ?? theme_service.ThemeMode.system;

        return MaterialApp(
          title: 'Jhonny - Family Task Manager',
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: theme_service.AppThemes.lightTheme,
          darkTheme: theme_service.AppThemes.darkTheme,
          themeMode: _mapToFlutterThemeMode(themeMode),

          // Localization
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
          ],

          // High contrast and accessibility
          highContrastTheme: _buildHighContrastTheme(Brightness.light),
          highContrastDarkTheme: _buildHighContrastTheme(Brightness.dark),

          // Navigation
          home: const AppWrapper(),

          // Global theme overrides
          builder: (context, child) {
            // Update system UI overlay based on theme
            _updateSystemUI(context);

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Ensure text doesn't scale beyond reasonable limits
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  ThemeMode _mapToFlutterThemeMode(theme_service.ThemeMode themeMode) {
    switch (themeMode) {
      case theme_service.ThemeMode.light:
        return ThemeMode.light;
      case theme_service.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_service.ThemeMode.system:
        return ThemeMode.system;
    }
  }

  void _updateSystemUI(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  ThemeData _buildHighContrastTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? theme_service.AppThemes.lightTheme
        : theme_service.AppThemes.darkTheme;

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        // Increase contrast for accessibility
        primary: brightness == Brightness.light ? Colors.black : Colors.white,
        onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
        secondary: brightness == Brightness.light
            ? Colors.grey[800]
            : Colors.grey[200],
        onSecondary:
            brightness == Brightness.light ? Colors.white : Colors.black,
        surface: brightness == Brightness.light ? Colors.white : Colors.black,
        onSurface: brightness == Brightness.light ? Colors.black : Colors.white,
      ),
      // Increase text contrast
      textTheme: baseTheme.textTheme.apply(
        bodyColor: brightness == Brightness.light ? Colors.black : Colors.white,
        displayColor:
            brightness == Brightness.light ? Colors.black : Colors.white,
      ),
    );
  }
}

class AppWrapper extends ConsumerWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseState = ref.watch(supabaseProvider);

    return supabaseState.when(
      data: (supabase) {
        return FutureBuilder<bool>(
          future: _checkOnboardingCompleted(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }

            final hasCompletedOnboarding = onboardingSnapshot.data ?? false;

            if (!hasCompletedOnboarding) {
              return const AppOnboardingPage();
            }

            final authState = ref.watch(authNotifierProvider);

            // Check if user is authenticated based on authState
            if (authState.user != null) {
              return const HomePage();
            } else {
              return const LoginPage();
            }
          },
        );
      },
      loading: () => const AppLoadingScreen(),
      error: (error, stack) => AppErrorScreen(error: error.toString()),
    );
  }

  Future<bool> _checkOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.pets,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'Jhonny',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Family Task Manager',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorScreen extends StatelessWidget {
  final String error;

  const AppErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
