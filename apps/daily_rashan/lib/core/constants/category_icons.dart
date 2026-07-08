import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Maps the backend category `icon` string (a Material icon identifier defined
/// in the backend category-master config) to a Flutter [IconData]. Falls back
/// to a sensible default so new icons never crash the UI.
IconData categoryIcon(String? name) {
  switch (name) {
    case 'eco':
      return Icons.eco;
    case 'grass':
      return Icons.grass;
    case 'spa':
      return Icons.spa;
    case 'nutrition':
      return Icons.nature;
    case 'yard':
      return Icons.yard;
    case 'egg_alt':
      return Icons.egg_alt;
    case 'water_drop':
      return Icons.water_drop;
    case 'crop_square':
      return Icons.crop_square;
    case 'bakery_dining':
      return Icons.bakery_dining;
    case 'square':
      return Icons.square;
    case 'set_meal':
      return Icons.set_meal;
    case 'icecream':
      return Icons.icecream;
    case 'rice_bowl':
      return Icons.rice_bowl;
    case 'breakfast_dining':
      return Icons.breakfast_dining;
    case 'cookie':
      return Icons.cookie;
    case 'grain':
      return Icons.grain;
    case 'blur_on':
      return Icons.blur_on;
    case 'dining':
      return Icons.dining;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'scatter_plot':
      return Icons.scatter_plot;
    case 'liquor':
      return Icons.liquor;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'blender':
      return Icons.blender;
    case 'wrap_text':
      return Icons.wrap_text;
    case 'lunch_dining':
      return Icons.lunch_dining;
    case 'local_pizza':
      return Icons.local_pizza;
    case 'cake':
      return Icons.cake;
    case 'emoji_food_beverage':
      return Icons.emoji_food_beverage;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'local_drink':
      return Icons.local_drink;
    case 'local_bar':
      return Icons.local_bar;
    case 'ac_unit':
      return Icons.ac_unit;
    case 'cleaning_services':
      return Icons.cleaning_services;
    case 'wash':
      return Icons.wash;
    case 'wc':
      return Icons.wc;
    case 'delete':
      return Icons.delete_outline;
    case 'back_hand':
      return Icons.back_hand;
    case 'dry_cleaning':
      return Icons.dry_cleaning;
    case 'sanitizer':
      return Icons.sanitizer;
    case 'inventory_2':
      return Icons.inventory_2;
    case 'layers':
      return Icons.layers;
    case 'description':
      return Icons.description;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'shaker':
      return Icons.restaurant;
    default:
      return Icons.category_outlined;
  }
}

/// The Material icon identifiers offered in the admin "assign icon" picker.
const List<String> kCategoryIconChoices = [
  'eco',
  'grass',
  'spa',
  'nutrition',
  'egg_alt',
  'water_drop',
  'rice_bowl',
  'grain',
  'local_fire_department',
  'liquor',
  'ramen_dining',
  'bakery_dining',
  'cake',
  'local_cafe',
  'ac_unit',
  'icecream',
  'cleaning_services',
  'inventory_2',
  'shopping_bag',
  'local_pizza',
];

/// Parses a `#RRGGBB` (or `#AARRGGBB`) hex colour string. Returns
/// [fallback] for null/invalid input.
Color categoryColor(String? hex, {Color fallback = AppColors.primaryGreen}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

/// A small curated palette for the admin colour picker.
const List<String> kCategoryColorChoices = [
  '#43A047',
  '#42A5F5',
  '#8D6E63',
  '#FB8C00',
  '#E53935',
  '#FDD835',
  '#D81B60',
  '#F4511E',
  '#C68642',
  '#795548',
  '#EC407A',
  '#6D4C41',
  '#26C6DA',
  '#AB47BC',
  '#00ACC1',
  '#78909C',
];
