// booking_history_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';

class BookingHistoryItem extends ConsumerWidget {
  final String title;
  final String startDate;
  final String endDate;
  final String price;
  final String status;
  final String? imagePath;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const BookingHistoryItem({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.status,
    this.imagePath,
    this.onEdit,
    this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blueAccent;
      default:
        return Colors.white;
    }
  }

  bool get _showEditButton =>
      status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'pending';

  bool get _showCancelButton =>
      status.toLowerCase() == 'confirmed' ||
      status.toLowerCase() == 'pending' ||
      status.toLowerCase() == 'ongoing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ip = ref.read(ipProvider.notifier).state;
    return Card(
      color: const Color(0xFF3B5998),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imagePath != null && imagePath!.isNotEmpty)
                  ? Image.network(
                      'http://$ip:8000/storage/$imagePath',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey,
                        child: const Icon(Icons.home, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey,
                      child: const Icon(Icons.home, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From: $startDate',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'To: $endDate',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: $price',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showEditButton)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: onEdit,
                              tooltip: 'Edit booking dates',
                            ),
                          if (_showCancelButton)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: onCancel,
                              tooltip: 'Cancel booking',
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
