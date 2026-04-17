import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A top banner displayed when the device has no internet connection.
///
/// Slides in from the top and fades in using [flutter_animate].
class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({
    super.key,
    this.message = 'No internet connection',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms),
    );
  }
}
