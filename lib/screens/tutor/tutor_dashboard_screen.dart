import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_tutor_profile_screen.dart';
import 'tutor_earnings_screen.dart';

import '../../models/booking.dart';
import '../../models/review.dart';
import '../../services/tutor_service.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  final _service = TutorService();

  late final Stream<List<Booking>> _requestsStream;
  late final Stream<List<Booking>> _upcomingStream;
  late final Stream<List<Booking>> _historyStream;
  late final Stream<List<Review>> _reviewsStream;

  // ============================================================
  // UI COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();

    _requestsStream = _service.watchIncomingRequests();
    _upcomingStream = _service.watchUpcomingSessions();
    _historyStream = _service.watchSessionHistory();
    _reviewsStream = _service.watchMyReviews();
  }

  bool _hasPaymentTerms(Booking session) {
    return session.paymentType != PaymentType.none ||
        session.amount > 0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: backgroundColor,

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'Tutor Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: 'My Earnings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TutorEarningsScreen(),
                  ),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const EditTutorProfileScreen(),
                  ),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                  );
                }
              },
            ),

            const SizedBox(width: 6),
          ],

          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFDDE1FF),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.inbox_outlined),
                text: 'Requests',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined),
                text: 'Upcoming',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'History',
              ),
              Tab(
                icon: Icon(Icons.star_outline),
                text: 'Feedback',
              ),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildRequests(),
            _buildUpcoming(),
            _buildHistory(),
            _buildFeedback(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REQUESTS
  // ============================================================

  Widget _buildRequests() {
    return StreamBuilder<List<Booking>>(
      stream: _requestsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (snap.hasError) {
          return _errorState(
            'Failed to load requests',
            snap.error.toString(),
          );
        }

        final requests = snap.data ?? [];

        if (requests.isEmpty) {
          return _emptyState(
            icon: Icons.inbox_outlined,
            title: 'No Pending Requests',
            subtitle: 'New student requests will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final b = requests[i];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: _cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _avatar(
                          Icons.person,
                          primaryColor,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.studentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                b.subject,
                                style: const TextStyle(
                                  color:
                                      secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _statusChip(
                          'Pending',
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _infoRow(
                      Icons.calendar_today_outlined,
                      '${b.date.toLocal().toString().split(' ')[0]}  ${b.time}',
                    ),

                    const SizedBox(height: 8),

                    _infoRow(
                      Icons.video_camera_front_outlined,
                      b.sessionType.name,
                    ),

                    if (b.studentMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"${b.studentMessage}"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _handleAccept(b),
                            icon: const Icon(
                              Icons.check,
                              size: 18,
                            ),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _handleDecline(b),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                            ),
                            label: const Text('Deny'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.red.shade600,
                              side: BorderSide(
                                color: Colors.red.shade200,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<void> _handleAccept(Booking b) async {
    final msgController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Accept Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: msgController,
          decoration: InputDecoration(
            labelText: 'Message for student',
            hintText: 'Optional message',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      msgController.dispose();
      return;
    }

    try {
      await _service.respondToBooking(
        bookingId: b.id,
        accept: true,
        tutorMessage: msgController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      msgController.dispose();
    }
  }

  // ============================================================
  // DECLINE
  // ============================================================

  Future<void> _handleDecline(Booking b) async {
    try {
      await _service.respondToBooking(
        bookingId: b.id,
        accept: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // ============================================================
  // UPCOMING
  // ============================================================

  Widget _buildUpcoming() {
    return StreamBuilder<List<Booking>>(
      stream: _upcomingStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (snap.hasError) {
          return _errorState(
            'Failed to load upcoming sessions',
            snap.error.toString(),
          );
        }

        final sessions = snap.data ?? [];

        if (sessions.isEmpty) {
          return _emptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No Upcoming Sessions',
            subtitle:
                'Accepted sessions will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final s = sessions[i];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: _cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _avatar(
                          Icons.school_outlined,
                          primaryColor,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.subject,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.studentName,
                                style: const TextStyle(
                                  color:
                                      secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _statusChip(
                          'Accepted',
                          Colors.green,
                        ),
                      ],
                    ),

                    if (s.sessionType ==
                        SessionType.monthly) ...[
                      const SizedBox(height: 14),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Session ${s.sessionNumber} of ${s.sessionsExpected}',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _infoRow(
                      Icons.calendar_today_outlined,
                      '${s.date.toLocal().toString().split(' ')[0]}  ${s.time}',
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 19,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          s.paymentStatus ==
                                  PaymentStatus.paid
                              ? 'Paid'
                              : 'Unpaid',
                          s.paymentStatus ==
                                  PaymentStatus.paid
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _handleCompleteSession(s),
                        icon: const Icon(
                          Icons.check_circle_outline,
                        ),
                        label:
                            const Text('Mark Session Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _hasPaymentTerms(s)
                            ? null
                            : () => _handleAddPayment(s),
                        icon: Icon(
                          _hasPaymentTerms(s)
                              ? Icons.check_circle_outline
                              : Icons.payments_outlined,
                        ),
                        label: Text(
                          _hasPaymentTerms(s)
                              ? 'Payment Terms Added'
                              : 'Add Payment Terms',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // COMPLETE SESSION
  // ============================================================

  Future<void> _handleCompleteSession(
    Booking session,
  ) async {
    try {
      await _service.markSessionCompleted(
        bookingId: session.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Session marked as completed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to complete session: $e'),
          ),
        );
      }
    }
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Future<void> _handleAddPayment(
    Booking session,
  ) async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) =>
          const _AddPaymentTermsDialog(),
    );

    if (result == null || !mounted) return;

    final PaymentType paymentType =
        result['paymentType'];

    final double amount = result['amount'];

    try {
      await _service.setPaymentTerms(
        bookingId: session.id,
        paymentType: paymentType,
        amount: amount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Payment terms saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to save payment terms: $e'),
        ),
      );
    }
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _buildHistory() {
    return StreamBuilder<List<Booking>>(
      stream: _historyStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (snap.hasError) {
          return _errorState(
            'Failed to load history',
            snap.error.toString(),
          );
        }

        final sessions = snap.data ?? [];

        if (sessions.isEmpty) {
          return _emptyState(
            icon: Icons.history,
            title: 'No Past Sessions',
            subtitle:
                'Completed sessions will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final s = sessions[i];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: _cardDecoration(),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(14),
                leading: _avatar(
                  Icons.school_outlined,
                  primaryColor,
                ),
                title: Text(
                  '${s.subject} • ${s.studentName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Padding(
                  padding:
                      const EdgeInsets.only(top: 6),
                  child: Text(
                    s.status.name,
                    style: const TextStyle(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  Widget _buildFeedback() {
    return StreamBuilder<List<Review>>(
      stream: _reviewsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (snap.hasError) {
          return _errorState(
            'Failed to load feedback',
            snap.error.toString(),
          );
        }

        final reviews = snap.data ?? [];

        if (reviews.isEmpty) {
          return _emptyState(
            icon: Icons.star_outline,
            title: 'No Feedback Yet',
            subtitle:
                'Student reviews will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, i) {
            final r = reviews[i];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _avatar(
                          Icons.person,
                          primaryColor,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            r.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),

                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < r.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          '"${r.comment}"',
                          style: const TextStyle(
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _avatar(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 23,
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        const SizedBox(width: 2),
        Icon(
          icon,
          size: 18,
          color: secondaryTextColor,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 38,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(
    String title,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 15),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD PAYMENT TERMS DIALOG
// UI ONLY REDESIGNED
// ============================================================

class _AddPaymentTermsDialog extends StatefulWidget {
  const _AddPaymentTermsDialog();

  @override
  State<_AddPaymentTermsDialog> createState() =>
      _AddPaymentTermsDialogState();
}

class _AddPaymentTermsDialogState
    extends State<_AddPaymentTermsDialog> {
  late final TextEditingController _amountController;

  PaymentType _selectedType =
      PaymentType.perSession;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    final amount =
        double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        _errorText =
            'Please enter a valid amount.';
      });
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).pop({
      'paymentType': _selectedType,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      title: const Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color:
                _TutorDashboardScreenState.primaryColor,
          ),
          SizedBox(width: 10),
          Text(
            'Payment Terms',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<PaymentType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Payment Type',
                prefixIcon: const Icon(
                  Icons.category_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: PaymentType.perSession,
                  child: Text('Per Session'),
                ),
                DropdownMenuItem(
                  value: PaymentType.monthlyContract,
                  child: Text('Monthly Contract'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 1000',
                prefixText: 'Rs. ',
                prefixIcon: const Icon(
                  Icons.currency_exchange,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                errorText: _errorText,
              ),
            ),

            if (_selectedType ==
                PaymentType.monthlyContract) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Text(
                  'Monthly contract: 4 sessions over 28 days.',
                  style: TextStyle(
                    color:
                        _TutorDashboardScreenState
                            .primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(
                context,
                rootNavigator: true,
              ).pop(),
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _TutorDashboardScreenState.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}