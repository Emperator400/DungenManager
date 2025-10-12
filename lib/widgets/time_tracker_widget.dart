// lib/widgets/time_tracker_widget.dart
import 'package:flutter/material.dart';

class TimeTrackerWidget extends StatelessWidget {
  final int totalMinutes;
  final Function(int) onTimeAdd;

  const TimeTrackerWidget({
    super.key,
    required this.totalMinutes,
    required this.onTimeAdd,
  });

  String _formatTime(int totalMinutes) {
    final int day = (totalMinutes / 1440).floor() + 1;
    final int minutesInDay = totalMinutes % 1440;
    final int hour = (minutesInDay / 60).floor();
    final int minute = minutesInDay % 60;

    final String hourStr = hour.toString().padLeft(2, '0');
    final String minuteStr = minute.toString().padLeft(2, '0');

    return "Tag $day, $hourStr:$minuteStr";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTime(totalMinutes),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(onPressed: () => onTimeAdd(10), child: const Text("+10 Min")),
            ElevatedButton(onPressed: () => onTimeAdd(60), child: const Text("+1 Std")),
            OutlinedButton(onPressed: () => onTimeAdd(60), child: const Text("Kurze Rast")),
            OutlinedButton(onPressed: () => onTimeAdd(480), child: const Text("Lange Rast")),
          ],
        )
      ],
    );
  }
}