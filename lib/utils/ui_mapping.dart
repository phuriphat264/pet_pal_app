// Maps the icon/color names the backend stores (plain strings, so they're
// JSON-safe) to the Flutter IconData/Color objects the existing screens
// already render. Keeps the UI code unchanged while the data source moves
// from hard-coded Dart maps to the API.
import 'package:flutter/material.dart';

const Map<String, IconData> _iconByName = {
  'local_hospital_rounded': Icons.local_hospital_rounded,
  'pets_rounded': Icons.pets_rounded,
  'store_rounded': Icons.store_rounded,
  'coffee_rounded': Icons.coffee_rounded,
  'hotel_rounded': Icons.hotel_rounded,
  'bathtub_rounded': Icons.bathtub_rounded,
  'park_rounded': Icons.park_rounded,
};

const String _defaultColorHex = '#5C3D2E';

IconData iconFromName(String? name) => _iconByName[name] ?? Icons.pets_rounded;

String iconToName(IconData icon) {
  for (final entry in _iconByName.entries) {
    if (entry.value == icon) return entry.key;
  }
  return 'pets_rounded';
}

Color colorFromHex(String? hex) {
  final value = (hex == null || hex.isEmpty) ? _defaultColorHex : hex;
  final cleaned = value.replaceFirst('#', '');
  final fullHex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(fullHex, radix: 16));
}

String colorToHex(Color color) {
  return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
