import 'package:flutter/material.dart';

class AppColors{
  AppColors._();

  static const Color primary = Color(0xFFE8FFD7);
  static const Color secondary = Color(0xFF93DA97);
  static const Color text = Color(0xFF3E5F44);

  static const Gradient linearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

