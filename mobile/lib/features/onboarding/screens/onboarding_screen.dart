import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.fastfood_rounded,
      color: Color(0xFFFF6B35),
      title: 'Order Delicious Food',
      subtitle: 'Browse hundreds of dishes from local restaurants and get exactly what you crave.',
    ),
    _SlideData(
      icon: Icons.delivery_dining_rounded,
      color: Color(0xFF3B82F6),
      title: 'Fast Delivery',
      subtitle: 'Get your food delivered right to your door — hot, fresh, and on time.',
    ),
    _SlideData(
      icon: Icons.track_changes_rounded,
      color: Color(0xFF10B981),
      title: 'Track Your Order',
      subtitle: 'Follow your order in real time from the kitchen to your doorstep.',
    ),
  ];

  void _finish() async {
    await StorageService().setOnboardingDone();
    if (mounted) context.go(AppRoutes.auth);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _SlidePage(data: _slides[index]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  key: ValueKey(isLast),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustrated icon container
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 88, color: data.color),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
