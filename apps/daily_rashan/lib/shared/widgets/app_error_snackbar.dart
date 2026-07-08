import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_exception.dart';

void showAppErrorSnackBar(BuildContext context, Object error) {
  final message = ApiException.friendlyMessage(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}
