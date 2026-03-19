import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:la_facu/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/subjects')) return 1;
    if (location.startsWith('/schedule')) return 2;
    if (location.startsWith('/tasks')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _ForgeNavBar(
        currentIndex: currentIndex,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/'); break;
            case 1: context.go('/subjects'); break;
            case 2: context.go('/schedule'); break;
            case 3: context.go('/tasks'); break;
            case 4: context.go('/settings'); break;
          }
        },
      ),
    );
  }
}

class _ForgeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ForgeNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final glassBorder = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded, label: 'Inicio', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.book_rounded, label: 'Materias', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.calendar_month_rounded, label: 'Horarios', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.task_alt_rounded, label: 'Tareas', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.tune_rounded, label: 'Config', index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = index == currentIndex;
    final activeColor = AppColors.primaryBlue;
    final inactiveColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
