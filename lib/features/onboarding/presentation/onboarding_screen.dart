import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: '¡Bienvenido a La Facu!',
      description: 'Tu nueva herramienta definitiva para organizar tu vida universitaria sin estrés.',
      icon: Icons.school_rounded,
      color: AppColors.primaryBlue,
    ),
    OnboardingData(
      title: 'Tu Cursada Bajo Control',
      description: 'Gestioná tus materias, tareas y exámenes en un solo lugar con un diseño minimalista y enfocado.',
      icon: Icons.assignment_rounded,
      color: AppColors.accentSage,
    ),
    OnboardingData(
      title: 'Sincronizá y Relajate',
      description: 'Integración real con Google Calendar y recordatorios automáticos para que nunca se te pase una entrega.',
      icon: Icons.notification_add_rounded,
      color: AppColors.accentAmber,
    ),
    OnboardingData(
      title: 'Enfoque Total',
      description: 'Diseñada para que pases menos tiempo organizando y más tiempo estudiando. ¡Vamos con todo!',
      icon: Icons.center_focus_strong_rounded,
      color: AppColors.primaryBlue,
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _OnboardingPage(data: page);
            },
          ),
          
          // Navegación Inferior
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicadores
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primaryBlue : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                // Botón Siguiente / Empezar
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_currentPage == _pages.length - 1 ? '¡EMPEZAR!' : 'SIGUIENTE'),
                ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                 .shimmer(duration: 2.seconds)
              ],
            ),
          ),
          
          // Saltear
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Saltear', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 100, color: data.color),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).shake(delay: 400.ms),
          
          const SizedBox(height: 48),
          
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 16),
          
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}
