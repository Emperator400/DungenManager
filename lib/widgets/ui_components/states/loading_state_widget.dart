import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbarer Loading State Widget
/// 
/// Zeigt einen konsistenten Ladezustand mit optionaler Nachricht.
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.color,
    this.size,
  });

  /// Standard Loading ohne Nachricht
  factory LoadingStateWidget.standard({
    Key? key,
    Color? color,
    double? size,
  }) {
    return LoadingStateWidget(
      key: key,
      color: color,
      size: size,
    );
  }

  /// Loading mit Nachricht
  factory LoadingStateWidget.withMessage({
    required String message,
    Key? key,
    Color? color,
    double? size,
  }) {
    return LoadingStateWidget(
      key: key,
      message: message,
      color: color,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? DnDTheme.ancientGold,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
