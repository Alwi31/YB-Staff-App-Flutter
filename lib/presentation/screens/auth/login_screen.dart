import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yb_staff_app/core/constants/app_strings.dart';
import 'package:yb_staff_app/core/theme/app_colors.dart';
import 'package:yb_staff_app/core/theme/app_spacing.dart';
import 'package:yb_staff_app/core/theme/app_typography.dart';
import 'package:yb_staff_app/presentation/providers/auth_provider.dart';
import 'package:yb_staff_app/presentation/widgets/app_text_field.dart';
import 'package:yb_staff_app/presentation/widgets/primary_button.dart';

const _logoAsset = 'assets/images/logo.png';
const _bgAsset = 'assets/images/login_bg.jpg';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      switch (next) {
        case AuthError(:final message):
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
              ),
            );
          ref.read(authProvider.notifier).clearError();
        case AuthAuthenticated():
          Navigator.of(context).pushReplacementNamed('/home');
        default:
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background image ────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),

          // ── Green gradient overlay — lebih gelap di bawah, ringan di atas
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withAlpha(76), // ~30% atas
                    AppColors.primary.withAlpha(140), // ~55% tengah
                    AppColors.primary.withAlpha(200), // ~78% bawah
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _LoginCard(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    isLoading: isLoading,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _handleSubmit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Login Card ────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandSection(),
            const SizedBox(height: AppSpacing.xxl),
            _HeadingSection(),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: AppStrings.emailLabel,
              controller: emailController,
              hint: AppStrings.emailHint,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.emailEmpty;
                }
                final emailRegex =
                    RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return AppStrings.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: AppStrings.passwordLabel,
              controller: passwordController,
              hint: AppStrings.passwordHint,
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.passwordEmpty;
                }
                if (value.length < 8) {
                  return AppStrings.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: AppStrings.loginButton,
              onPressed: onSubmit,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand Section ─────────────────────────────────────────────────────────────

class _BrandSection extends StatelessWidget {
  const _BrandSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 80),
          child: Image.asset(
            _logoAsset,
            height: 80,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(height: 2),
        Text(
          AppStrings.systemName,
          style: AppTypography.captionSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.portalSubtitle,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Heading Section ───────────────────────────────────────────────────────────

class _HeadingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.loginTitle, style: AppTypography.headingLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.loginSubtitle,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
