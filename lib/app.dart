import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/services/fcm_service.dart';
import 'package:yb_staff_app/core/utils/navigator_key.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_theme.dart';
import 'package:yb_staff_app/core/widgets/connectivity_observer.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';
import 'package:yb_staff_app/presentation/providers/notification_provider.dart';
import 'package:yb_staff_app/presentation/screens/auth/login_screen.dart';
import 'package:yb_staff_app/presentation/screens/home/home_screen.dart';
import 'package:yb_staff_app/presentation/screens/notification/notification_screen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.instance.initNotifications(
        onNewMessage: () {
          ref.read(notificationProvider.notifier).incrementUnreadCount();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sync FCM token with backend whenever auth state changes.
    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        try {
          final repo = ref.read(notificationRepositoryProvider);
          await FcmService.instance.requestPermissionAndRegister(
            onTokenReceived: (token) async {
              await repo.registerFcmToken(token);
            },
          );
        } catch (_) {}
        ref.read(notificationProvider.notifier).refreshUnreadCount();
      } else if (previous is AuthAuthenticated && next is! AuthAuthenticated) {
        try {
          final token = await FcmService.instance.getToken();
          if (token != null) {
            await ref
                .read(notificationRepositoryProvider)
                .revokeFcmToken(token);
          }
          await FcmService.instance.deleteToken();
        } catch (_) {}
      }
    });

    return MaterialApp(
      title: 'YukBersihin Staff',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.light,
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          ConnectivityObserver(child: child ?? const SizedBox.shrink()),
      initialRoute: '/',
      routes: {
        '/': (_) => const _SplashRouter(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/notifications': (_) => const NotificationScreen(),
      },
    );
  }
}

// ── Splash / token-check router ───────────────────────────────────────────────

class _SplashRouter extends ConsumerStatefulWidget {
  const _SplashRouter();

  @override
  ConsumerState<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends ConsumerState<_SplashRouter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _checkToken();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkToken() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.getToken();

    String destination;
    if (token == null || token.isEmpty) {
      destination = '/login';
    } else {
      final restored = await ref.read(authProvider.notifier).restoreSession();
      destination = restored ? '/home' : '/login';
    }

    FlutterNativeSplash.remove();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 100,
                  height: 128,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
