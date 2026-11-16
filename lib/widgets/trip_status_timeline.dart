import 'package:flutter/material.dart';

import '../models/trip.dart';

class TripStatusTimeline extends StatelessWidget {
  final TripStatus status;

  const TripStatusTimeline({super.key, required this.status});

  static const _stages = [
    (TripStatus.requested, 'Dicari'),
    (TripStatus.accepted, 'Menuju'),
    (TripStatus.arrived, 'Tiba'),
    (TripStatus.inProgress, 'Berangkat'),
    (TripStatus.completed, 'Selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == TripStatus.cancelled) {
      return const Text(
        'Perjalanan dibatalkan',
        style: TextStyle(fontWeight: FontWeight.w600),
      );
    }

    final currentIndex = _stages.indexWhere((stage) => stage.$1 == status);
    final activeColor = Theme.of(context).colorScheme.secondary;
    const inactiveColor = Color(0xFFD8DDD2);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < _stages.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i <= currentIndex ? activeColor : inactiveColor,
                  ),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i <= currentIndex ? activeColor : inactiveColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < _stages.length; i++)
              Expanded(
                child: Text(
                  _stages[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == _stages.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == currentIndex
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: i == currentIndex
                        ? Theme.of(context).colorScheme.onSurface
                        : const Color(0xFF687064),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
