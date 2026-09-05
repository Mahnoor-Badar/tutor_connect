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
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F7FC);

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
        if (day.weekday == DateTime.sunday) {
          return false;
        }

        return !_holidaysService.isHoliday(day, _holidays);
      },
    );

    if (picked == null) return;

    if (picked.year != now.year) {
      await _loadHolidays(picked.year);

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

  Future<void> _pickTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first.'),
        ),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    if (!mounted) return;

    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final minute = picked.minute.toString().padLeft(2, '0');
    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';

    setState(() {
      _selectedTime = '$hour:$minute $period';
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

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: primaryColor,
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _selectionCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
    required bool selected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? primaryColor
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Book with ${widget.tutor.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: _loadingHolidays
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                30,
              ),
              children: [
                // ---------------- HEADER ----------------

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            widget.tutor.photoUrl.isNotEmpty
                                ? NetworkImage(widget.tutor.photoUrl)
                                : null,
                        child: widget.tutor.photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Book a Session',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Request a session with ${widget.tutor.name}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------- SUBJECT ----------------

                if (widget.tutor.subjects.isNotEmpty) ...[
                  _sectionTitle(
                    'Subject',
                    subtitle: 'Choose what you want to learn',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: _inputDecoration(
                      label: 'Select Subject',
                      icon: Icons.menu_book_rounded,
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                ],

                const SizedBox(height: 24),

                // ---------------- DATE ----------------

                _sectionTitle(
                  'Date',
                  subtitle: 'Select a suitable day for your session',
                ),
                const SizedBox(height: 10),

                _selectionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Session Date',
                  value: _selectedDate == null
                      ? 'Pick a date'
                      : _formatDate(_selectedDate!),
                  onTap: _pickDate,
                  selected: _selectedDate != null,
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sundays and public holidays are unavailable.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------------- TIME ----------------

                _sectionTitle(
                  'Time',
                  subtitle: 'Choose when you want the session',
                ),
                const SizedBox(height: 10),

                _selectionCard(
                  icon: Icons.access_time_rounded,
                  title: 'Session Time',
                  value: _selectedTime ?? 'Pick a time',
                  onTap: _selectedDate == null
                      ? null
                      : _pickTime,
                  selected: _selectedTime != null,
                ),

                const SizedBox(height: 24),

                // ---------------- SESSION TYPE ----------------

                _sectionTitle(
                  'Session Type',
                  subtitle: 'Choose the type of tutoring arrangement',
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RadioGroup<String>(
                    groupValue: _sessionType,
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _sessionType = value;
                      });
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'runtime',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          activeColor: primaryColor,
                          title: const Text(
                            'One-time Session',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Book a single tutoring session',
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        RadioListTile<String>(
                          value: 'monthly',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          activeColor: primaryColor,
                          title: const Text(
                            'Monthly Plan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Weekly sessions for 4 weeks',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ---------------- MESSAGE ----------------

                _sectionTitle(
                  'Message',
                  subtitle: 'Tell the tutor anything they should know',
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    label: 'Message to tutor (optional)',
                    icon: Icons.chat_bubble_outline_rounded,
                    hint: 'Write a message for the tutor...',
                  ),
                ),

                const SizedBox(height: 28),

                // ---------------- INFO ----------------

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: primaryColor,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your request will be sent to the tutor. '
                          'The tutor can review your request and accept '
                          'or decline it based on their availability.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------- SUBMIT ----------------

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Request Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}