import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum ToastType { success, error, info }

void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.success,
}) {
  Color bg;
  IconData icon;
  switch (type) {
    case ToastType.success:
      bg = AppColors.success;
      icon = Icons.check_circle_outline;
      break;
    case ToastType.error:
      bg = AppColors.danger;
      icon = Icons.error_outline;
      break;
    case ToastType.info:
      bg = AppColors.mainBlue;
      icon = Icons.info_outline;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
}
