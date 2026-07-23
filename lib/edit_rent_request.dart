import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';

class EditRentRequestScreen extends ConsumerStatefulWidget {
  const EditRentRequestScreen({super.key});

  @override
  ConsumerState<EditRentRequestScreen> createState() =>
      _EditRentRequestScreenState();
}

class _EditRentRequestScreenState extends ConsumerState<EditRentRequestScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;

      final response = await http.get(
        Uri.parse('http://$ip:8000/api/user/owner/updaterentals'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is Map && data.containsKey('updaterentals')) {
            _requests = data['updaterentals'] ?? [];
          } else {
            _requests = [];
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load requests: ${response.statusCode}'),
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

  Future<void> _approveRequest(int requestId) async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.post(
        Uri.parse(
          'http://$ip:8000/api/user/owner/updaterental/$requestId/approve',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental update approved successfully!')),
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

  Future<void> _rejectRequest(int requestId) async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.post(
        Uri.parse(
          'http://$ip:8000/api/user/owner/updaterental/$requestId/reject',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental update rejected successfully!')),
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

  void _confirmApprove(int requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text(
          'Are you sure you want to approve this rental update?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _approveRequest(requestId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(int requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text(
          'Are you sure you want to reject this rental update?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _rejectRequest(requestId);
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
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  String? _firstImagePath(dynamic apartment) {
    final images = apartment?['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map && first.containsKey('image_path')) {
        return first['image_path']?.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ip = ref.read(ipProvider.notifier).state;

    return Scaffold(
      appBar: AppBar(title: const Text('Editing rent requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(
              child: Text(
                'No rental update requests found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final req = _requests[index] as Map<String, dynamic>;
                  final rental = (req['rental'] ?? {}) as Map<String, dynamic>;
                  final apartment =
                      (rental['apartment'] ?? {}) as Map<String, dynamic>;

                  final title = apartment['title']?.toString() ?? 'Unknown';
                  final newStartDate = req['new_start_date']?.toString() ?? '';
                  final newEndDate = req['new_end_date']?.toString() ?? '';
                  final status = req['status']?.toString() ?? 'unknown';
                  final imagePath = _firstImagePath(apartment);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: const Color(0xFF3B5998),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (imagePath != null && imagePath.isNotEmpty)
                                  ? Image.network(
                                      'http://$ip:8000/storage/$imagePath',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) =>
                                          Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.home,
                                              color: Colors.white,
                                            ),
                                          ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'New Start: $newStartDate',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'New End: $newEndDate',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status: $status',
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (status.toLowerCase() == 'pending')
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Reject update',
                                              onPressed: () {
                                                _confirmReject(
                                                  req['id'] as int,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Approve update',
                                              onPressed: () {
                                                _confirmApprove(
                                                  req['id'] as int,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.check_box_rounded,
                                                color: Colors.green,
                                              ),
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
                    ),
                  );
                },
              ),
            ),
    );
  }
}
