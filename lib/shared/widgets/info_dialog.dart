import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.mainBlue, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mainBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Ho capito'),
        ),
      ],
    ),
  );
}
