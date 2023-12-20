import 'dart:ui';

enum Category {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  other
}

class Category {
  Category({
    required this.name,
    required this.color,
  });
  String name;
  Color color;

}
