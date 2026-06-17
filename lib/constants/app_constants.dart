import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Orman Pazar';
  static const String listingsCollection = 'listings';
  static const String temporarySellerId = 'test-user';

  static const List<String> categories = [
    'Yakacak Odun',
    'Kereste',
    'Tomruk',
    'Talaş',
    'Diğer',
  ];

  static const List<String> woodTypes = [
    'Meşe',
    'Çam',
    'Gürgen',
    'Kayın',
    'Diğer',
  ];

  static const List<String> units = ['kg', 'ton', 'ster', 'm³', 'çuval'];

  static const List<String> moistureStatuses = ['Kuru', 'Yaş', 'Karışık'];

  static const Color forestGreen = Color(0xFF285A36);
  static const Color leafGreen = Color(0xFF4F7F45);
  static const Color cream = Color(0xFFF6F1E7);
  static const Color cardBackground = Color(0xFFFFFCF5);
  static const Color woodBrown = Color(0xFF7A5634);
  static const Color mutedText = Color(0xFF6D6A61);
}
