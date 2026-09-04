import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'session_notes_screen.dart';
import 'feedback_screen.dart';

import '../../models/booking.dart';

class MySessionsScreen extends StatelessWidget {
  const MySessionsScreen({super.key});

  Stream<List<Booking>> _sessionsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: user.uid)
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromDoc(doc)).toList(),
        );
  }

  String _statusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      body: StreamBuilder<List<Booking>>(
        stream: _sessionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load sessions.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'No sessions yet.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book a session with a tutor to see it here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your Sessions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              ...sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SessionCard(
                    session: session,
                    statusText: _statusText(session.status),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Booking session;
  final String statusText;

  const _SessionCard({required this.session, required this.statusText});

  Color _getStatusColor() {
    switch (session.status) {
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.declined:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.pending:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tutor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        session.subject,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(_formatDate(session.date)),

                const SizedBox(width: 20),

                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(session.time),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  session.isPaid ? Icons.check_circle : Icons.pending,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  session.isPaid ? 'Payment Completed' : 'Payment Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: session.isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (session.status == BookingStatus.completed) ...[
              const SizedBox(height: 16),

              // Session Notes button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SessionNotesScreen(session: session),
                      ),
                    );
                  },
                  icon: const Icon(Icons.note_alt_outlined),
                  label: const Text('Session Notes'),
                ),
              ),

              const SizedBox(height: 10),

              // Feedback button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeedbackScreen(session: session),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Give Feedback'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}