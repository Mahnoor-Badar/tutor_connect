
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

class TutorEarningsScreen extends StatefulWidget {
  const TutorEarningsScreen({super.key});

  @override
  State<TutorEarningsScreen> createState() =>
      _TutorEarningsScreenState();
}

class _TutorEarningsScreenState extends State<TutorEarningsScreen> {
  final EarningsService _earningsService = EarningsService();

  late Future<double> _totalEarnings;
  late Future<double> _monthlyEarnings;
  late Future<int> _totalStudents;
  late Future<int> _completedSessions;
  late Future<List<Map<String, dynamic>>> _studentEarnings;

  // ============================================================
  // UI COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() {
    _totalEarnings = _earningsService.getTotalEarnings();
    _monthlyEarnings = _earningsService.getMonthlyEarnings();
    _totalStudents = _earningsService.getTotalStudents();
    _completedSessions =
        _earningsService.getCompletedSessions();
    _studentEarnings =
        _earningsService.getStudentEarnings();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadEarnings();
    });

    await Future.wait([
      _totalEarnings,
      _monthlyEarnings,
      _totalStudents,
      _completedSessions,
      _studentEarnings,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'My Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ==================================================
            // EARNINGS HEADER
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF6366F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.20),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Earnings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track your tutoring income',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // TOTAL + MONTHLY EARNINGS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _EarningCard(
                    title: 'Total Earnings',
                    icon: Icons.account_balance_wallet_outlined,
                    future: _totalEarnings,
                    prefix: 'Rs. ',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EarningCard(
                    title: 'This Month',
                    icon: Icons.calendar_month_outlined,
                    future: _monthlyEarnings,
                    prefix: 'Rs. ',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // STUDENTS + SESSIONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _CountCard(
                    title: 'Students',
                    icon: Icons.people_outline,
                    future: _totalStudents,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountCard(
                    title: 'Completed',
                    icon: Icons.check_circle_outline,
                    future: _completedSessions,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // STUDENT EARNINGS TITLE
            // ==================================================

            _sectionTitle(
              icon: Icons.people_outline,
              title: 'Student Earnings',
            ),

            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _studentEarnings,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _loadingCard();
                }

                if (snapshot.hasError) {
                  return _errorCard(
                    'Unable to load student earnings.',
                  );
                }

                final students = snapshot.data ?? [];

                if (students.isEmpty) {
                  return _emptyCard(
                    icon: Icons.people_outline,
                    title: 'No Student Earnings Yet',
                    subtitle:
                        'Students with completed paid sessions will appear here.',
                  );
                }

                return Column(
                  children: students.map((student) {
                    final name =
                        student['studentName'] ?? 'Student';

                    final amount =
                        (student['totalEarnings'] ?? 0)
                            .toDouble();

                    final sessions =
                        (student['sessions'] ?? 0) as int;

                    final nameText = name.toString();

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      decoration: _cardDecoration(),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),

                        leading: _studentAvatar(
                          nameText,
                        ),

                        title: Text(
                          nameText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$sessions completed '
                                '${sessions == 1 ? 'session' : 'sessions'}',
                                style: const TextStyle(
                                  color:
                                      secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Earned',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Rs. ${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // RECENT EARNINGS
            // ==================================================

            _sectionTitle(
              icon: Icons.receipt_long_outlined,
              title: 'Recent Earnings',
            ),

            const SizedBox(height: 12),

            StreamBuilder(
              stream: _earningsService.watchTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _loadingCard();
                }

                if (snapshot.hasError) {
                  return _errorCard(
                    'Unable to load earnings.',
                  );
                }

                final transactions =
                    snapshot.data?.docs ?? [];

                if (transactions.isEmpty) {
                  return _emptyCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Earnings Yet',
                    subtitle:
                        'Completed paid sessions and contracts will appear here.',
                  );
                }

                return Column(
                  children: transactions.map((doc) {
                    final data = doc.data();

                    final amount =
                        (data['amount'] ?? 0).toDouble();

                    final subject =
                        data['subject'] ?? 'Session';

                    final studentName =
                        data['studentName'] ?? 'Student';

                    final paymentType =
                        data['paymentType'] ?? 'perSession';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      decoration: _cardDecoration(),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),

                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.green
                                .withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.green,
                          ),
                        ),

                        title: Text(
                          subject.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 5),
                          child: Text(
                            '$studentName • '
                            '${paymentType == 'monthlyContract' ? 'Monthly Contract' : 'Per Session'}',
                            style: const TextStyle(
                              color: secondaryTextColor,
                            ),
                          ),
                        ),

                        trailing: Text(
                          '+ Rs. ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
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

  // ============================================================
  // STUDENT AVATAR
  // ============================================================

  Widget _studentAvatar(String name) {
    final letter = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING CARD
  // ============================================================

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: _cardDecoration(),
      child: const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EARNING CARD
// ============================================================

class _EarningCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<double> future;
  final String prefix;

  const _EarningCard({
    required this.title,
    required this.icon,
    required this.future,
    required this.prefix,
  });

  static const Color primaryColor =
      Color(0xFF4F46E5);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryTextColor =
      Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FutureBuilder<double>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: Text('Unable to load'),
              ),
            );
          }

          final value = snapshot.data ?? 0;

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      primaryColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 21,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '$prefix${value.toStringAsFixed(0)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// COUNT CARD
// ============================================================

class _CountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> future;

  const _CountCard({
    required this.title,
    required this.icon,
    required this.future,
  });

  static const Color primaryColor =
      Color(0xFF4F46E5);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryTextColor =
      Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FutureBuilder<int>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox(
              height: 60,
              child: Center(
                child: Text('Unable to load'),
              ),
            );
          }

          final value = snapshot.data ?? 0;

          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      primaryColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ),

              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

