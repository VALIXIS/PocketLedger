import 'package:flutter/material.dart';
import '../utilities/category_ui_helper.dart';

class CategoryAvatar extends StatelessWidget {
  final String categoryId;
  final double radius;
  final double iconSize;

  const CategoryAvatar({
    super.key,
    required this.categoryId,
    this.radius = 20.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final icon = CategoryUiHelper.getIcon(categoryId);
    final color = CategoryUiHelper.getColor(categoryId);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}
