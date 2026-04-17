import 'package:flutter/material.dart';

/// A shimmer-style loading placeholder.
///
/// Renders a rounded rectangle that pulses between two shades,
/// mimicking the shape of the content being loaded.
class LoadingSkeletonWidget extends StatefulWidget {
  const LoadingSkeletonWidget({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// Convenience widget that stacks multiple skeleton lines to mimic a card.
class LoadingSkeletonCard extends StatelessWidget {
  const LoadingSkeletonCard({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < lines; i++) ...[
              LoadingSkeletonWidget(
                width: i == 0 ? null : 160,
                height: i == 0 ? 20 : 14,
              ),
              if (i < lines - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
