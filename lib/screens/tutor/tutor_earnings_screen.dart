import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

class TutorEarningsScreen extends StatefulWidget {
  const TutorEarningsScreen({super.key});

  @override
  State<TutorEarningsScreen> createState() =>
      _TutorEarningsScreenState();
}

class _TutorEarningsScreenState
    extends State<TutorEarningsScreen> {
  final EarningsService _earningsService = EarningsService();

  late Future<double> _totalEarnings;
  late Future<double> _monthlyEarnings;
  late Future<int> _totalStudents;
  late Future<int> _completedSessions;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() {
    _totalEarnings =
        _earningsService.getTotalEarnings();

    _monthlyEarnings =
        _earningsService.getMonthlyEarnings();

    _totalStudents =
        _earningsService.getTotalStudents();

    _completedSessions =
        _earningsService.getCompletedSessions();
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ==================================================
            // TOTAL EARNINGS
            // ==================================================

            _EarningCard(
              title: 'Total Earnings',
              icon: Icons.account_balance_wallet_outlined,
              future: _totalEarnings,
              prefix: 'Rs. ',
            ),

            const SizedBox(height: 12),

            // ==================================================
            // MONTHLY EARNINGS
            // ==================================================

            _EarningCard(
              title: 'This Month',
              icon: Icons.calendar_month_outlined,
              future: _monthlyEarnings,
              prefix: 'Rs. ',
            ),

            const SizedBox(height: 12),

            // ==================================================
            // STUDENTS
            // ==================================================

            _CountCard(
              title: 'Students',
              icon: Icons.people_outline,
              future: _totalStudents,
            ),

            const SizedBox(height: 12),

            // ==================================================
            // COMPLETED SESSIONS
            // ==================================================

            _CountCard(
              title: 'Completed Sessions',
              icon: Icons.check_circle_outline,
              future: _completedSessions,
            ),

            const SizedBox(height: 24),

            const Text(
              'Recent Earnings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TRANSACTIONS
            // ==================================================

            StreamBuilder(
              stream:
                  _earningsService.watchTransactions(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load earnings.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  );
                }

                final transactions =
                    snapshot.data?.docs ?? [];

                if (transactions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 45,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No earnings yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Completed paid sessions will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: transactions.map((doc) {
                    final data = doc.data();

                    final amount =
                        (data['amount'] ?? 0).toDouble();

                    final subject =
                        data['subject'] ?? 'Session';

                    final paymentType =
                        data['paymentType'] ??
                            'perSession';

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 10),

                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.attach_money,
                          ),
                        ),

                        title: Text(
                          subject.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          paymentType == 'monthlyContract'
                              ? 'Monthly Contract Session'
                              : 'Per Session',
                        ),

                        trailing: Text(
                          'Rs. ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: FutureBuilder<double>(
          future: future,

          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox(
                height: 55,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Text(
                'Unable to load',
              );
            }

            final value = snapshot.data ?? 0;

            return Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Icon(icon),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '$prefix${value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: FutureBuilder<int>(
          future: future,

          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox(
                height: 55,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Text(
                'Unable to load',
              );
            }

            final value = snapshot.data ?? 0;

            return Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Icon(icon),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}