import 'package:flutter/material.dart';

const Map<String, IconData> _iconMap = {
  'briefcase': Icons.business_center_outlined,
  'gift': Icons.card_giftcard_outlined,
  'circle-plus': Icons.add_circle_outline,
  'plus-circle': Icons.add_circle_outline,
  'shopping-cart': Icons.shopping_cart_outlined,
  'cart': Icons.shopping_cart_outlined,
  'zap': Icons.bolt,
  'car': Icons.directions_car_outlined,
  'film': Icons.movie_creation_outlined,
  'clapperboard': Icons.movie_creation_outlined,
  'home': Icons.home_outlined,
  'heart-pulse': Icons.monitor_heart_outlined,
  'activity': Icons.monitor_heart_outlined,
  'heart': Icons.favorite_outline,
  'credit-card': Icons.credit_card_outlined,
  'coffee': Icons.local_cafe_outlined,
  'cup-soda': Icons.local_cafe_outlined,
  'piggy-bank': Icons.savings_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'trending-up': Icons.trending_up,
  'trending-down': Icons.trending_down,
  'utensils': Icons.restaurant_outlined,
  'shopping-bag': Icons.shopping_bag_outlined,
  'music': Icons.music_note_outlined,
  'book': Icons.book_outlined,
  'phone': Icons.phone_outlined,
  'globe': Icons.public,
  'plane': Icons.flight_outlined,
  'train': Icons.train_outlined,
  'bus': Icons.directions_bus_outlined,
  'bike': Icons.directions_bike_outlined,
  'dumbbell': Icons.fitness_center_outlined,
  'wrench': Icons.build_outlined,
  'tool': Icons.build_outlined,
  'shield': Icons.shield_outlined,
  'star': Icons.star_outline,
  'tag': Icons.label_outline,
  'package': Icons.inventory_2_outlined,
  'dollar-sign': Icons.attach_money,
  'percent': Icons.percent,
  'bar-chart': Icons.bar_chart,
  'pie-chart': Icons.pie_chart_outline,
  'refresh-cw': Icons.sync,
  'repeat': Icons.repeat,
  'settings': Icons.settings_outlined,
  'user': Icons.person_outline,
  'users': Icons.people_outline,
  'building': Icons.business_outlined,
  'landmark': Icons.account_balance_outlined,
  'banknote': Icons.payments_outlined,
  'coins': Icons.monetization_on_outlined,
  'wrench-screwdriver': Icons.build_outlined,
};

bool _isEmoji(String s) => s.runes.any((r) => r > 127);

IconData _resolve(String icon) =>
    _iconMap[icon.toLowerCase()] ?? Icons.category_outlined;

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color,
  });

  final String icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (_isEmoji(icon)) {
      return Text(icon, style: TextStyle(fontSize: size));
    }
    return Icon(
      _resolve(icon),
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
