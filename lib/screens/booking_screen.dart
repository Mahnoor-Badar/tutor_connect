import 'package:flutter/material.dart';

import '../models/tutor_profile.dart';
import '../services/booking_service.dart';
import '../services/holiday_service.dart';
class BookingScreen extends StatefulWidget {
  final TutorProfile tutor;

  const BookingScreen({
    super.key,
    required this.tutor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final HolidaysService _holidaysService = HolidaysService();

  final TextEditingController _messageCtrl = TextEditingController();

  Set<DateTime> _holidays = {};

  bool _loadingHolidays = true;
  bool _submitting = false;

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedSubject;

  String _sessionType = 'runtime';

  // Fixed time slots for now.
  // These can later be replaced with tutor-specific availability.
  static const List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.tutor.subjects.isNotEmpty) {
      _selectedSubject = widget.tutor.subjects.first;
    }

    _loadHolidays(DateTime.now().year);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  // Remove the time portion from a DateTime.
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadHolidays(int year) async {
    if (mounted) {
      setState(() {
        _loadingHolidays = true;
      });
    }

    try {
      final holidays = await _holidaysService.getHolidays(year);

      if (!mounted) return;

      setState(() {
        _holidays = holidays;
        _loadingHolidays = false;
      });
    } catch (_) {
      if (!mounted) return;

      // If the holiday API fails, allow booking to continue.
      setState(() {
        _holidays = {};
        _loadingHolidays = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: (day) {
        // Sundays are unavailable.
        if (day.weekday == DateTime.sunday) {
          return false;
        }

        // Only check holidays that have been loaded.
        return !_holidaysService.isHoliday(day, _holidays);
      },
    );

    if (picked == null) return;

    // If the selected date belongs to another year,
    // load that year's holidays before accepting it.
    if (picked.year != now.year) {
      await _loadHolidays(picked.year);

      // Check again after loading the correct year's holidays.
      if (_holidaysService.isHoliday(picked, _holidays)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This date is a public holiday. Please choose another date.',
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedDate = _dateOnly(picked);
      _selectedTime = null;
    });
  }

  bool get _canSubmit {
    return _selectedDate != null &&
        _selectedTime != null &&
        _selectedSubject != null &&
        !_submitting;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
    });

    try {
      await _bookingService.createBooking(
        tutorId: widget.tutor.uid,
        subject: _selectedSubject!,
        date: _selectedDate!,
        time: _selectedTime!,
        sessionType: _sessionType,
        studentMessage: _messageCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String message = 'Unable to create booking. Please try again.';

      final error = e.toString();

      if (error.contains('already booked')) {
        message = 'This slot is already booked. Please choose another time.';
      } else if (error.contains('permission-denied')) {
        message = 'You do not have permission to create this booking.';
      } else if (error.contains('network')) {
        message = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with ${widget.tutor.name}'),
      ),
      body: _loadingHolidays
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------------- SUBJECT ----------------

                if (widget.tutor.subjects.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.tutor.subjects
                        .map(
                          (subject) => DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ---------------- DATE ----------------

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate == null
                        ? 'Pick a date'
                        : _formatDate(_selectedDate!),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _pickDate,
                ),

                const Text(
                  'Sundays and public holidays are unavailable.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------- TIME ----------------

                const Text(
                  'Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final selected = _selectedTime == slot;

                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: _selectedDate == null
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTime = slot;
                                });
                              }
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ---------------- SESSION TYPE ----------------

                const Text(
                  'Session Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('One-time'),
                  value: 'runtime',
                  groupValue: _sessionType,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _sessionType = value;
                    });
                  },
                ),

                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monthly (weekly, 4 sessions)'),
                  value: 'monthly',
                  groupValue: _sessionType,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _sessionType = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // ---------------- MESSAGE ----------------

                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message to tutor (optional)',
                    hintText: 'Write a message for the tutor...',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------- SUBMIT ----------------

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Request Booking',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
