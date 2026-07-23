import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';

class RentRequestScreen extends ConsumerStatefulWidget {
  const RentRequestScreen({super.key});

  @override
  ConsumerState<RentRequestScreen> createState() => _RentRequestScreenState();
}

class _RentRequestScreenState extends ConsumerState<RentRequestScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final ip = ref.read(ipProvider.notifier).state;
      final token = ref.read(tokenProvider);

      final response = await http.get(
        Uri.parse('http://$ip:8000/api/user/owner/rentals'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _requests = data['rentals'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load requests')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveRequest(int rentalId) async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;

      final response = await http.post(
        Uri.parse('http://$ip:8000/api/user/owner/rentals/$rentalId/approve'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental approved successfully!')),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve rental: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving rental: $e')));
    }
  }

  Future<void> _rejectRequest(int rentalId) async {
    try {
      final ip = ref.read(ipProvider.notifier).state;
      final token = ref.read(tokenProvider);

      final response = await http.post(
        Uri.parse('http://$ip:8000/api/user/owner/rentals/$rentalId/reject'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental rejected successfully!')),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject rental: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting rental: $e')));
    }
  }

  void _confirmApprove(int rentalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text('Are you sure you want to approve this rental?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _approveRequest(rentalId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(int rentalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this rental?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _rejectRequest(rentalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ip = ref.read(ipProvider.notifier).state;
    return Scaffold(
      appBar: AppBar(title: Text('Rent requests'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? Center(
              child: Text(
                'No rental requests found'.tr,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  final apartment = req['apartment'] ?? {};
                  final title = apartment['title'] ?? 'Unknown';
                  final startDate = req['start_date'] ?? '';
                  final endDate = req['end_date'] ?? '';
                  final images = apartment['images'] ?? [];
                  final status = req['status'] ?? 'unknown';

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: const Color(0xFF3B5998),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: images.isNotEmpty
                                  ? Image.network(
                                      'http://$ip:8000/storage/${images[0]['image_path']}',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey,
                                      child: const Icon(
                                        Icons.home,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Start: $startDate',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'End: $endDate',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (status == 'pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _confirmReject(req['id']);
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            _confirmApprove(req['id']);
                                          },
                                          icon: const Icon(
                                            Icons.check_box_rounded,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Status:'.tr + '$status'.tr,
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
