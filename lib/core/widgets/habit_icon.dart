import 'package:flutter/material.dart';

/// Widget to display habit icons from codePoints
/// This wraps IconData construction to isolate tree-shaking warnings
class HabitIcon extends StatelessWidget {
  final int? codePoint;
  final Color? color;
  final double? size;

  const HabitIcon({
    Key? key,
    required this.codePoint,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (codePoint == null) {
      return Icon(Icons.star, color: color, size: size);
    }
    
    return Icon(
      IconData(codePoint!, fontFamily: 'MaterialIcons'),
      color: color,
      size: size,
    );
  }
}
