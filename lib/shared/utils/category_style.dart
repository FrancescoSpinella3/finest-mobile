import 'package:flutter/material.dart';

const List<Color> categoryColorPalette = [
  Color(0xFF34D399),
  Color(0xFFA78BFA),
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFFF87171),
  Color(0xFF38BDF8),
  Color(0xFFFB923C),
  Color(0xFF4ADE80),
  Color(0xFFF472B6),
  Color(0xFF818CF8),
];

/// Deterministic color for a category, stable across the whole app
/// regardless of screen, sort order, or transaction type.
Color categoryColor(String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) {
    return categoryColorPalette.last;
  }
  final index = categoryId.hashCode.abs() % categoryColorPalette.length;
  return categoryColorPalette[index];
}
