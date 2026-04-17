import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal model mirroring the tracking state used in OrderTrackingScreen.
class TrackingState {
  const TrackingState({
    this.status = 'pending',
    this.driverName,
    this.history = const [],
  });

  final String status;
  final String? driverName;
  final List<String> history;

  TrackingState copyWith({
    String? status,
    String? driverName,
    List<String>? history,
  }) =>
      TrackingState(
        status: status ?? this.status,
        driverName: driverName ?? this.driverName,
        history: history ?? this.history,
      );
}

/// Simulated notifier that processes WebSocket events.
class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  /// Simulates receiving an OrderStatusUpdated WebSocket event.
  void onStatusUpdate(Map<String, dynamic> event) {
    final newStatus = event['status'] as String? ?? state.status;
    final driver    = event['driver'] as Map<String, dynamic>?;

    state = state.copyWith(
      status:     newStatus,
      driverName: driver?['name'] as String?,
      history:    [...state.history, newStatus],
    );
  }
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>(
  (_) => TrackingNotifier(),
);

void main() {
  group('OrderTrackingScreen WebSocket status update', () {
    test('initial status is pending', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(trackingProvider);
      expect(state.status, equals('pending'));
    });

    test('onStatusUpdate changes status to confirmed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(trackingProvider.notifier).onStatusUpdate({
        'order_id': 1,
        'status': 'confirmed',
      });

      expect(container.read(trackingProvider).status, equals('confirmed'));
    });

    test('status updates accumulate in history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(trackingProvider.notifier);
      notifier.onStatusUpdate({'status': 'confirmed'});
      notifier.onStatusUpdate({'status': 'preparing'});
      notifier.onStatusUpdate({'status': 'out_for_delivery'});

      final state = container.read(trackingProvider);
      expect(state.history, equals(['confirmed', 'preparing', 'out_for_delivery']));
      expect(state.status, equals('out_for_delivery'));
    });

    test('driver name is set when out_for_delivery event includes driver', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(trackingProvider.notifier).onStatusUpdate({
        'status': 'out_for_delivery',
        'driver': {'id': 5, 'name': 'Ahmed Sayed'},
      });

      final state = container.read(trackingProvider);
      expect(state.driverName, equals('Ahmed Sayed'));
    });

    test('status without driver does not clear existing driver name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(trackingProvider.notifier);
      notifier.onStatusUpdate({
        'status': 'out_for_delivery',
        'driver': {'name': 'Mohamed'},
      });
      notifier.onStatusUpdate({'status': 'delivered'});

      // Driver name should persist after delivered update
      expect(container.read(trackingProvider).driverName, equals('Mohamed'));
    });
  });
}
