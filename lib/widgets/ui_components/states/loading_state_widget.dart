import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key, this.message, this.color, this.size});

  final String? message;
  final Color? color;
  final double? size;

  factory LoadingStateWidget.standard({Key? key, Color? color, double? size}) =>
      LoadingStateWidget(key: key, color: color, size: size);

  factory LoadingStateWidget.withMessage({
    required String message,
    Key? key,
    Color? color,
    double? size,
  }) =>
      LoadingStateWidget(key: key, message: message, color: color, size: size);

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color ?? C.accent),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(fontSize: 16, color: C.textMid)),
          ],
        ],
      ),
    );
  }
}
