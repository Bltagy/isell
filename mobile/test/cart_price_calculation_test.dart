import 'package:flutter_test/flutter_test.dart';
import 'package:isell/features/cart/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('CartState price calculation', () {
    test('subtotal is sum of item price × quantity', () {
      const item1 = CartItem(
        productId: 1,
        name: 'Burger',
        price: 8000, // 80 EGP
        quantity: 2,
      );
      const item2 = CartItem(
        productId: 2,
        name: 'Drink',
        price: 3500, // 35 EGP
        quantity: 1,
      );

      const state = CartState(items: [item1, item2]);

      // 2 × 8000 + 1 × 3500 = 19500
      expect(state.subtotal, equals(19500));
    });

    test('subtotal is 0 for empty cart', () {
      const state = CartState();
      expect(state.subtotal, equals(0));
    });

    test('CartItem subtotal equals price × quantity', () {
      const item = CartItem(
        productId: 1,
        name: 'Pizza',
        price: 14000,
        quantity: 3,
      );
      expect(item.subtotal, equals(42000));
    });

    test('copyWith updates quantity correctly', () {
      const item = CartItem(
        productId: 1,
        name: 'Burger',
        price: 8000,
        quantity: 1,
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, equals(5));
      expect(updated.subtotal, equals(40000));
    });

    test('CartNotifier addItem increases quantity for existing product', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      notifier.addItem(
        productId: 1,
        name: 'Burger',
        price: 8000,
        quantity: 1,
      );
      notifier.addItem(
        productId: 1,
        name: 'Burger',
        price: 8000,
        quantity: 2,
      );

      final state = container.read(cartProvider);
      expect(state.items.length, equals(1));
      expect(state.items.first.quantity, equals(3));
      expect(state.subtotal, equals(24000));
    });

    test('CartNotifier removeItem removes product from cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(productId: 1, name: 'Burger', price: 8000, quantity: 1);
      notifier.addItem(productId: 2, name: 'Drink',  price: 3500, quantity: 1);

      notifier.removeItem(1);

      final state = container.read(cartProvider);
      expect(state.items.length, equals(1));
      expect(state.items.first.productId, equals(2));
    });

    test('discount reduces effective total', () {
      const item = CartItem(
        productId: 1,
        name: 'Burger',
        price: 10000,
        quantity: 1,
      );
      const state = CartState(items: [item], discount: 2000);
      // subtotal = 10000, discount = 2000 → effective = 8000
      expect(state.subtotal - state.discount, equals(8000));
    });
  });
}
