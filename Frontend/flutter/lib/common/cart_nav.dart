import 'package:flutter/material.dart';
import 'package:flutter_food_app/view/cart/cart_view.dart';

void openAppCart(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(builder: (_) => const CartView()),
  );
}
