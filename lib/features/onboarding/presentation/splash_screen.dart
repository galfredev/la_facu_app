import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/features/settings/data/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStart();
  }

  void _handleStart() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    // Simular carga de 2 segundos antes de navegar
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      if (onboardingDone) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Minimalista con animación de pulso
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 50,
                color: AppColors.primaryBlue,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut)
            .shimmer(delay: 500.ms, duration: 2.seconds, color: Colors.white24),
            
            const SizedBox(height: 32),
            
            // Nombre de la App
            Text(
              'La Facu',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                letterSpacing: 2,
                fontSize: 40,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'ESTUDIANTE ENFOCADO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accentSage,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 100),
            
            // Indicador de carga sutil
            SizedBox(
              width: 40,
              height: 4,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
