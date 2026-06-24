import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Orman Pazar';
  static const String listingsCollection = 'listings';
  static const String usersCollection = 'users';
  static const String allCategories = 'Tümü';

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

  static const Color forestGreen = Color(0xFF244E34);
  static const Color deepGreen = Color(0xFF163323);
  static const Color leafGreen = Color(0xFF5D8B4E);
  static const Color mossGreen = Color(0xFFDDE8D4);
  static const Color sage = Color(0xFF8EA86F);
  static const Color clay = Color(0xFFC46F3A);
  static const Color cream = Color(0xFFF7F2E8);
  static const Color cardBackground = Color(0xFFFFFCF6);
  static const Color woodBrown = Color(0xFF7A5634);
  static const Color amber = Color(0xFFE2A94B);
  static const Color mutedText = Color(0xFF6D6A61);
  static const Color border = Color(0xFFE7DDCD);
}
