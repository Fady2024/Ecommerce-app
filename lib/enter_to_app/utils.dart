import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSnackBar(String title, String message, Icon icon) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.blue.withOpacity(0.4),
    icon: icon,
    snackPosition: SnackPosition.BOTTOM,
    borderRadius: 20,
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    snackStyle: SnackStyle.GROUNDED,
    barBlur: 30,
    duration: const Duration(milliseconds: 2000),
    isDismissible: true,
  );
}
