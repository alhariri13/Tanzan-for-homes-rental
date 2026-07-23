import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tanzan/providers/ip_provider.dart';
import 'dart:convert';
import 'package:tanzan/providers/token_provider.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final int apartmentId;

  const PropertyDetailsScreen({super.key, required this.apartmentId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  Map<String, dynamic>? _apartment;
  bool _loading = true;

  final Color _cardColor = const Color(0xFF282A3A);
  final Color _backgroundColor = const Color(0xFF1B1C27);

  @override
  void initState() {
    super.initState();
    _fetchApartment();
  }

  Future<void> _fetchApartment() async {
    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.get(
        Uri.parse('http://$ip:8000/api/user/apartments/${widget.apartmentId}'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _apartment = data['apartment'] ?? data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load apartment details: ${response.statusCode}',
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_apartment == null) {
      return const Scaffold(
        body: Center(child: Text('No apartment data found')),
      );
    }

    final List images = (_apartment!['images'] as List?) ?? [];
    final String title = _apartment!['title']?.toString() ?? 'Property Details';

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 5.0, color: Colors.black54)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.isNotEmpty ? images.length : 1,
                    itemBuilder: (context, index) {
                      if (images.isEmpty) {
                        return Container(
                          color: _cardColor,
                          child: const Center(
                            child: Icon(
                              Icons.apartment,
                              color: Colors.grey,
                              size: 80,
                            ),
                          ),
                        );
                      }
                      final ip = ref.read(ipProvider.notifier).state;
                      final src =
                          'http://$ip:8000/storage/${images[index]['image_path']}';
                      return Image.network(
                        src,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: _cardColor,
                            child: const Center(
                              child: Icon(
                                Icons.apartment,
                                color: Colors.grey,
                                size: 80,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${images.isNotEmpty ? images.length : 0} Photos'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PropertyDetailsCard(property: _apartment!),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class PropertyDetailsCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsCard({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailsCard> createState() =>
      _PropertyDetailsCardState();
}

class _PropertyDetailsCardState extends ConsumerState<PropertyDetailsCard> {
  final Color _cardColor = const Color(0xFF282A3A);
  final Color _blueAccent = Colors.blueAccent;
  final Color _textColor = Colors.white;

  double _currentRating = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;
  double _dailyPrice = 0.0;
  String _address = 'N/A';
  double _totalPrice = 0.0;

  List<DateTimeRange> _availableDateRanges = [];
  bool _loadingAvailability = true;

  String _comment = "";

  @override
  void initState() {
    super.initState();
    // Only use backend rate
    _currentRating = (widget.property['rate'] as num?)?.toDouble() ?? 0.0;

    final priceRaw = widget.property['price_per_night'];
    if (priceRaw is String) {
      _dailyPrice = double.tryParse(priceRaw) ?? 150.0;
    } else if (priceRaw is num) {
      _dailyPrice = priceRaw.toDouble();
    } else {
      _dailyPrice = 150.0;
    }

    _address = widget.property['address']?.toString() ?? 'Unknown Location'.tr;

    _calculateTotalPrice();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    try {
      final int apartmentId = widget.property['id'];
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.get(
        Uri.parse(
          'http://$ip:8000/api/user/apartments/$apartmentId/availability',
        ),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['AvailablePeriod'] != null) {
          final List periods = data['AvailablePeriod'];
          setState(() {
            _availableDateRanges = periods.map<DateTimeRange>((item) {
              final start = DateTime.parse(item['start_date']);
              final end = DateTime.parse(item['end_date']);
              return DateTimeRange(start: start, end: end);
            }).toList();
            _loadingAvailability = false;
          });
        } else {
          setState(() => _loadingAvailability = false);
          final msg = data['message']?.toString() ?? 'No availability data'.tr;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        setState(() => _loadingAvailability = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load availability.'.tr)),
        );
      }
    } catch (e) {
      setState(() => _loadingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e'.tr)));
    }
  }

  void _calculateTotalPrice() {
    if (_startDate != null && _endDate != null) {
      final duration = _endDate!.difference(_startDate!).inDays;
      final days = duration > 0 ? duration : 1;
      _totalPrice = days * _dailyPrice;
    } else {
      _totalPrice = 0.0;
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = RegExp(r'\d+').firstMatch(value)?.group(0);
      return int.tryParse(cleaned ?? '') ?? 0;
    }
    return 0;
  }

  bool _isDateInAnyRange(DateTime day) {
    for (final range in _availableDateRanges) {
      if (day.isAfter(range.start.subtract(const Duration(days: 1))) &&
          day.isBefore(range.end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  DateTimeRange? _rangeForDate(DateTime day) {
    for (final range in _availableDateRanges) {
      if (day.isAfter(range.start.subtract(const Duration(days: 1))) &&
          day.isBefore(range.end.add(const Duration(days: 1)))) {
        return range;
      }
    }
    return null;
  }

  DateTime _findValidInitialDate({required bool isStart}) {
    final List<DateTime> validDates = [];
    for (final range in _availableDateRanges) {
      DateTime current = range.start;
      while (!current.isAfter(range.end)) {
        validDates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    if (validDates.isEmpty) {
      return DateTime.now().add(const Duration(days: 1));
    }
    if (isStart) {
      return validDates.first;
    } else {
      return validDates.firstWhere(
        (d) => _startDate == null || d.isAfter(_startDate!),
        orElse: () => validDates.last,
      );
    }
  }

  Future<void> _pickSingleDate({required bool isStart}) async {
    final DateTime initialDate = _findValidInitialDate(isStart: isStart);
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = firstDate.add(const Duration(days: 365 * 2));

    DateTimeRange? allowedRange;
    if (!isStart && _startDate != null) {
      allowedRange = _rangeForDate(_startDate!);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime day) {
        if (_loadingAvailability) return false;
        if (allowedRange != null) {
          return day.isAfter(
                allowedRange.start.subtract(const Duration(days: 1)),
              ) &&
              day.isBefore(allowedRange.end.add(const Duration(days: 1)));
        }
        return _isDateInAnyRange(day);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _blueAccent,
              onPrimary: Colors.white,
              surface: _cardColor,
              onSurface: _textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          final sameRange = _rangeForDate(_startDate!);
          if (_endDate != null &&
              (_endDate!.isBefore(_startDate!) ||
                  (sameRange != null &&
                      (_endDate!.isBefore(sameRange.start) ||
                          _endDate!.isAfter(sameRange.end))))) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate!.subtract(const Duration(days: 1));
          } else if (_startDate == null) {
            _startDate = _endDate!.subtract(const Duration(days: 1));
          }
        }
        _calculateTotalPrice();
      });
    }
  }

  bool _isChosenRangeValid() {
    if (_startDate == null || _endDate == null) return false;
    final DateTimeRange? range = _rangeForDate(_startDate!);
    if (range == null) return false;
    return !_endDate!.isAfter(range.end) && !_startDate!.isBefore(range.start);
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please select both Start and End dates.'.tr),
        ),
      );
      return;
    }

    if (!_isChosenRangeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Selected dates are not available.'.tr),
        ),
      );
      return;
    }

    final int apartmentId = widget.property['id'];
    final token = ref.read(tokenProvider);

    final String start = _startDate!.toIso8601String().substring(0, 10);
    final String end = _endDate!.toIso8601String().substring(0, 10);

    try {
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.post(
        Uri.parse('http://$ip:8000/api/user/apartments/$apartmentId/rent'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'start_date': start, 'end_date': end}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _blueAccent,
            content: Text('Booking request sent successfully.'.tr),
          ),
        );
      } else {
        final msg = (() {
          try {
            final m = jsonDecode(response.body);
            return m['message']?.toString() ??
                'Failed to send booking request.'.tr;
          } catch (_) {
            return 'Failed to send booking request.'.tr;
          }
        })();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error: $e'.tr),
        ),
      );
    }
  }

  void _handleRatingSubmission(double rating, String comment) {
    // Do not change _currentRating locally—only backend value is shown
    _sendRatingToServer(rating, comment);
  }

  Future<void> _sendRatingToServer(double rating, String comment) async {
    try {
      final int apartmentId = widget.property['id'];
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.post(
        Uri.parse('http://$ip:8000/api/user/apartment/$apartmentId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted successfully!'.tr)),
        );
        // Keep showing backend rate; optionally re-fetch apartment to update
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review.'.tr)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e'.tr)));
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isStart,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickSingleDate(isStart: isStart),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: _cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: date != null ? _blueAccent : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null ? label : date.toString().substring(0, 10),
                style: TextStyle(
                  color: date == null ? Colors.white54 : _textColor,
                  fontWeight: date == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              Icon(
                Icons.calendar_month,
                color: date != null ? _blueAccent : Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDatesList() {
    if (_loadingAvailability) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator(color: _blueAccent)),
      );
    }

    if (_availableDateRanges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(
          'No specific available periods listed.'.tr,
          style: const TextStyle(
            color: Colors.redAccent,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    _availableDateRanges.sort((a, b) => a.start.compareTo(b.start));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          'Available Periods for Rent:'.tr,
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ..._availableDateRanges.map((range) {
          final start = range.start.toString().substring(0, 10);
          final end = range.end.toString().substring(0, 10);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'From: $start'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  'To: $end'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _buildRatingDialog() async {
    double selectedRating = 5.0;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _cardColor,
              title: Text(
                'Rate This Property'.tr,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'How many stars would you give?'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 26,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedRating = (index + 1).toDouble();
                              });
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${selectedRating.toInt()} Stars'.tr,
                    style: TextStyle(
                      color: _blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write your comment here...'.tr,
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) => _comment = val,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel'.tr,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(
                    'Submit'.tr,
                    style: TextStyle(
                      color: _blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    _handleRatingSubmission(selectedRating, _comment);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureDetail(IconData icon, dynamic value, String label) {
    return Column(
      children: [
        Icon(icon, color: _blueAccent, size: 30),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRating(double rating) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    final List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 18));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 18));
      } else {
        stars.add(
          Icon(Icons.star_border, color: Colors.grey.shade700, size: 18),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingAndContactArea() {
    final bool isBookingEnabled = _startDate != null && _endDate != null;
    final int daysCount = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDateField(
                label: 'Start Date'.tr,
                date: _startDate,
                isStart: true,
              ),
              const SizedBox(width: 15),
              _buildDateField(
                label: 'End Date'.tr,
                date: _endDate,
                isStart: false,
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (daysCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total for $daysCount Days:'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contacting Agent...'.tr)),
                    );
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: Text(
                    'Agent'.tr,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isBookingEnabled ? _submitBooking : null,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Confirm Booking'.tr,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int bedrooms = _parseInt(widget.property['number_of_bedrooms']);
    final int bathrooms = _parseInt(widget.property['number_of_bathrooms']);
    final int area = _parseInt(widget.property['area']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.property['title']?.toString() ?? 'Property'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildRating(_currentRating),
            ],
          ),
          const SizedBox(height: 10),

          // Address
          Row(
            children: [
              Icon(Icons.location_on, color: _blueAccent, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _address,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Price
          Row(
            children: [
              Text(
                '\$${_dailyPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _blueAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/night'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Features
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureDetail(Icons.bed, bedrooms, 'Bedrooms'.tr),
              _buildFeatureDetail(Icons.bathtub, bathrooms, 'Bathrooms'.tr),
              _buildFeatureDetail(Icons.square_foot, area, 'Area'.tr),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            'Description'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.property['description']?.toString() ?? 'No description'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Availability list
          _buildAvailableDatesList(),
          const SizedBox(height: 20),

          // Booking & Contact
          _buildBookingAndContactArea(),
          const SizedBox(height: 20),

          // Rating button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _buildRatingDialog,
              icon: const Icon(Icons.star, color: Colors.white),
              label: Text(
                'Rate'.tr,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
