import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_facu/core/auth/google_auth_service.dart';
import 'package:la_facu/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _didAutoRedirect = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final account = await ref.read(googleAuthProvider.notifier).login();
      if (account != null && mounted) {
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al iniciar sesiÃ³n: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAutoRedirect) return;

    final account = ref.read(googleAuthProvider);
    if (account != null) {
      _didAutoRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserInfo?>(googleAuthProvider, (previous, next) {
      if (next != null && mounted && !_didAutoRedirect) {
        _didAutoRedirect = true;
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _showSuccess ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
            ),
          ),
          // Background Decor (Glows)
          Positioned(
            top: -100,
            right: -100,
            child: _CircleGlow(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _CircleGlow(
              color: AppColors.accentSage.withValues(alpha: 0.1),
              size: 250,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Icon/Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primaryBlue,
                      size: 40,
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'La Facu',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),
                  Text(
                    'Tu asistente acadÃ©mico inteligente',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 60),

                  // Benefits Section
                  _BenefitItem(
                    icon: Icons.sync_rounded,
                    title: 'SincronizaciÃ³n total',
                    subtitle: 'Toda tu cursada conectada con Google Calendar.',
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                  const SizedBox(height: 20),

                  _BenefitItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notificaciones inteligentes',
                    subtitle:
                        'Alertas automÃƒÂ¡ticas para que no se te pase nada.',
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                  const SizedBox(height: 20),

                  _BenefitItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'PersonalizaciÃ³n premium',
                    subtitle: 'DiseÃ±o adaptado a tu estilo de estudio.',
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

                  const Spacer(),

                  // Login Button
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'INGRESAR CON GOOGLE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showSuccess
                        ? Container(
                            key: const ValueKey('google-success'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.12),
                                  AppColors.accentSage.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.14,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Cuenta conectada. Preparando tu espacio personal...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty-success')),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'CONTINUAR SIN CUENTA',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 12),
                  Text(
                    'GalfreDev',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _CircleGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
