import 'package:flutter/material.dart';

Color darkenColor(Color color, [double amount = 0.1]) {
  int r = color.red;
  int g = color.green;
  int b = color.blue;

  int rDark = (r * (1 - amount)).toInt();
  int gDark = (g * (1 - amount)).toInt();
  int bDark = (b * (1 - amount)).toInt();

  return Color.fromARGB(color.alpha, rDark, gDark, bDark);
}
