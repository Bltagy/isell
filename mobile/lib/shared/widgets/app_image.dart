import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a network image with loading/error fallback.
/// Falls back to an icon placeholder if [url] is null or empty.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final bg = placeholderColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    if (url == null || url!.isEmpty) {
      return _placeholder(context, bg);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _shimmer(bg),
        errorWidget: (_, __, ___) => _placeholder(context, bg),
      ),
    );
  }

  Widget _shimmer(Color bg) => _ShimmerBox(width: width, height: height, bg: bg);

  Widget _placeholder(BuildContext context, Color bg) => Container(
        width: width,
        height: height,
        color: bg,
        child: Center(
          child: Icon(
            placeholderIcon,
            size: (height ?? 48) * 0.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: 'Image placeholder',
          ),
        ),
      );
}

// Shimmer placeholder — uses a single AnimationController shared via
// an InheritedWidget would be ideal at scale, but a local controller is
// fine for individual images and avoids coupling.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, this.height, required this.bg});
  final double? width;
  final double? height;
  final Color bg;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: widget.bg,
        ),
      ),
    );
  }
}
