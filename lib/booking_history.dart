// booking_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';
import 'package:tanzan/booking_history_item.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.get(
        Uri.parse('http://$ip:8000/api/user/rentals'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookings = (data['rentals'] ?? []) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  String? _firstImagePath(List<dynamic> images) {
    if (images.isEmpty) return null;
    final first = images.first;
    if (first is Map<String, dynamic>) {
      return first['image_path']?.toString();
    }
    if (first is String) return first;
    return null;
  }

  Future<void> _updateBooking({
    required int bookingId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.put(
        Uri.parse('http://$ip:8000/api/user/rentals/$bookingId/update'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'start_date': startDate, 'end_date': endDate}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully!')),
        );
        await _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating booking: $e')));
    }
  }

  /// Cancel booking via Laravel POST route
  Future<void> _cancelBooking(int bookingId, String title) async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.post(
        Uri.parse('http://$ip:8000/api/user/rentals/$bookingId/cancel'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking "$title" cancelled successfully!')),
        );
        await _fetchBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cancelling booking: $e')));
    }
  }

  void _openEditSheet({
    required BuildContext context,
    required String currentStart,
    required String currentEnd,
    required String title,
    required int bookingId,
  }) {
    DateTime? _startDate;
    DateTime? _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> _pickDate({required bool isStart}) async {
              final initial =
                  DateTime.tryParse(isStart ? currentStart : currentEnd) ??
                  DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() {
                  if (isStart) {
                    _startDate = picked;
                  } else {
                    _endDate = picked;
                  }
                });
              }
            }

            String _displayDate(DateTime? d, String fallback) {
              if (d == null) return fallback;
              return d.toIso8601String().substring(0, 10);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Booking: $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _pickDate(isStart: true),
                          child: Text(
                            'Start: ${_displayDate(_startDate, currentStart)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _pickDate(isStart: false),
                          child: Text(
                            'End: ${_displayDate(_endDate, currentEnd)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      final startStr =
                          _startDate?.toIso8601String().substring(0, 10) ??
                          currentStart;
                      final endStr =
                          _endDate?.toIso8601String().substring(0, 10) ??
                          currentEnd;

                      Navigator.pop(ctx);

                      await _updateBooking(
                        bookingId: bookingId,
                        startDate: startStr,
                        endDate: endStr,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCancel({
    required BuildContext context,
    required String title,
    required int bookingId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking'),
        content: Text('Are you sure you want to cancel "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelBooking(bookingId, title);
            },
            child: Text('Yes, cancel'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking history'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? Center(
              child: Text(
                'No bookings found'.tr,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index] as Map<String, dynamic>;
                  final apartment =
                      (booking['apartment'] ?? {}) as Map<String, dynamic>;
                  final title = apartment['title']?.toString() ?? 'Unknown';
                  final startDate = _formatDate(
                    booking['start_date']?.toString(),
                  );
                  final endDate = _formatDate(booking['end_date']?.toString());
                  final price = booking['total_price']?.toString() ?? '';
                  final status = booking['status']?.toString() ?? 'unknown';
                  final images = (apartment['images'] ?? []) as List<dynamic>;
                  final imagePath = _firstImagePath(images);
                  final bookingId = booking['id'] is int
                      ? booking['id'] as int
                      : int.tryParse('${booking['id']}') ?? index;

                  return BookingHistoryItem(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    price: price,
                    status: status,
                    imagePath: imagePath,
                    onEdit: () {
                      _openEditSheet(
                        context: context,
                        currentStart: startDate,
                        currentEnd: endDate,
                        title: title,
                        bookingId: bookingId,
                      );
                    },
                    onCancel: () {
                      _confirmCancel(
                        context: context,
                        title: title,
                        bookingId: bookingId,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
