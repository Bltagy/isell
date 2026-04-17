import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/storage_service.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.options = const {},
    this.imageUrl,
  });

  final int productId;
  final String name;
  final int price; // piastres
  final int quantity;
  final Map<int, Set<int>> options;
  final String? imageUrl;

  int get subtotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        options: options,
        imageUrl: imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'options': options.map(
          (k, v) => MapEntry(k.toString(), v.toList()),
        ),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as int,
        name: json['name'] as String,
        price: json['price'] as int,
        quantity: json['quantity'] as int,
        imageUrl: json['imageUrl'] as String?,
        options: (json['options'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            int.parse(k),
            Set<int>.from((v as List).cast<int>()),
          ),
        ),
      );
}

class CartState {
  const CartState({
    this.items = const [],
    this.promoCode,
    this.discount = 0,
    this.addressId,
  });

  final List<CartItem> items;
  final String? promoCode;
  final int discount; // piastres
  final int? addressId;

  int get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);

  CartState copyWith({
    List<CartItem>? items,
    String? promoCode,
    int? discount,
    int? addressId,
  }) =>
      CartState(
        items: items ?? this.items,
        promoCode: promoCode ?? this.promoCode,
        discount: discount ?? this.discount,
        addressId: addressId ?? this.addressId,
      );
}

class CartNotifier extends Notifier<CartState> {
  static const _key = 'cart_items';

  @override
  CartState build() {
    return _load();
  }

  CartState _load() {
    final box = Hive.box<dynamic>(HiveBoxes.cart);
    final raw = box.get(_key) as String?;
    if (raw == null) return const CartState();
    try {
      final list = jsonDecode(raw) as List;
      final items = list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return CartState(items: items);
    } catch (_) {
      return const CartState();
    }
  }

  Future<void> _persist(CartState s) async {
    final box = Hive.box<dynamic>(HiveBoxes.cart);
    await box.put(_key, jsonEncode(s.items.map((e) => e.toJson()).toList()));
  }

  void addItem({
    required int productId,
    required String name,
    required int price,
    required int quantity,
    Map<int, Set<int>> options = const {},
    String? imageUrl,
  }) {
    final existing = state.items.indexWhere((i) => i.productId == productId);
    List<CartItem> updated;
    if (existing >= 0) {
      updated = [...state.items];
      updated[existing] = updated[existing]
          .copyWith(quantity: updated[existing].quantity + quantity);
    } else {
      updated = [
        ...state.items,
        CartItem(
          productId: productId,
          name: name,
          price: price,
          quantity: quantity,
          options: options,
          imageUrl: imageUrl,
        ),
      ];
    }
    state = state.copyWith(items: updated);
    _persist(state);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items
        .map((i) => i.productId == productId ? i.copyWith(quantity: quantity) : i)
        .toList();
    state = state.copyWith(items: updated);
    _persist(state);
  }

  void removeItem(int productId) {
    final updated = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: updated);
    _persist(state);
  }

  void setPromoCode(String? code, {int discount = 0}) {
    state = state.copyWith(promoCode: code, discount: discount);
  }

  void setAddress(int addressId) {
    state = state.copyWith(addressId: addressId);
  }

  void clear() {
    state = const CartState();
    _persist(state);
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
