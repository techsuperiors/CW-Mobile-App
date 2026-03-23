import 'package:flutter/material.dart';

class RequestTabTheme {
  static Color colorForIndex(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFE91E8C);
      case 1:
        return const Color(0xFF0086C9);
      case 2:
        return const Color(0xFF12B76A);
      case 3:
        return const Color(0xFFF04438);
      default:
        return Colors.grey;
    }
  }
}
