import 'package:flutter/material.dart';
import '../../models/ride_request.dart';
import '../../services/ride_repository.dart';
import '../../utils/format.dart';

class RideListTab extends StatelessWidget {
  const RideListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RideRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final items = repo.items;

        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada pesanan'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _RideCard(request: items[i]),
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideRequest request;
  const _RideCard({required this.request});

  Color get _statusColor => switch (request.status) {
        RideStatus.pending => Colors.orange,
        RideStatus.accepted => Colors.blue,
        RideStatus.rejected => Colors.red,
        RideStatus.completed => Colors.green,
        RideStatus.cancelled => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatDateTime(request.scheduledAt),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(request.status.label,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.location_on, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(request.pickup)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.flag, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(request.destination)),
          ]),
          const SizedBox(height: 8),
          Text('${request.passengerCount} penumpang',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (request.status == RideStatus.pending) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => RideRepository.instance
                    .updateStatus(request.id, RideStatus.cancelled),
                child: const Text('Batalkan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}