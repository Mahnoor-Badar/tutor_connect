import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_tutor_profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tutor Dashboard'),

          // Logout button
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditTutorProfileScreen(),
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
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],

          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
              Tab(text: 'Feedback'),
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

  // ------------------------------------------------------------
  // Requests tab
  // ------------------------------------------------------------

  Widget _buildRequests() {
    return StreamBuilder<List<Booking>>(
      stream: _service.watchIncomingRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load requests:\n\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final requests = snap.data ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final b = requests[i];

            return Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b.studentName} • ${b.subject}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${b.date.toLocal().toString().split(' ')[0]}  ${b.time}',
                    ),
                    Text('Type: ${b.sessionType.name}'),

                    if (b.studentMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '"${b.studentMessage}"',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _handleAccept(b),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _handleDecline(b),
                          child: const Text('Deny'),
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

  Future<void> _handleAccept(Booking b) async {
    final msgController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept request'),
        content: TextField(
          controller: msgController,
          decoration: const InputDecoration(
            labelText: 'Message for student (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      msgController.dispose();
    }
  }

  Future<void> _handleDecline(Booking b) async {
    try {
      await _service.respondToBooking(bookingId: b.id, accept: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ------------------------------------------------------------
  // Upcoming tab
  // ------------------------------------------------------------

  Widget _buildUpcoming() {
    return StreamBuilder<List<Booking>>(
      stream: _service.watchUpcomingSessions(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load upcoming sessions:\n\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final sessions = snap.data ?? [];

        if (sessions.isEmpty) {
          return const Center(child: Text('No upcoming sessions'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final s = sessions[i];

            return ListTile(
              title: Text('${s.subject} • ${s.studentName}'),
              subtitle: Text(
                '${s.date.toLocal().toString().split(' ')[0]}  ${s.time}',
              ),
              trailing: s.isPaid
                  ? const Chip(label: Text('Paid'))
                  : const Chip(label: Text('Unpaid')),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // History tab
  // ------------------------------------------------------------

  Widget _buildHistory() {
    return StreamBuilder<List<Booking>>(
      stream: _service.watchSessionHistory(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load history:\n\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final sessions = snap.data ?? [];

        if (sessions.isEmpty) {
          return const Center(child: Text('No past sessions yet'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final s = sessions[i];

            return ListTile(
              title: Text('${s.subject} • ${s.studentName}'),
              subtitle: Text(s.status.name),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Feedback tab
  // ------------------------------------------------------------

  Widget _buildFeedback() {
    return StreamBuilder<List<Review>>(
      stream: _service.watchMyReviews(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load feedback:\n\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final reviews = snap.data ?? [];

        if (reviews.isEmpty) {
          return const Center(child: Text('No feedback yet'));
        }

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, i) {
            final r = reviews[i];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(r.studentName)),
                    Row(
                      children: List.generate(
                        5,
                        (idx) => Icon(
                          idx < r.rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(r.comment),
              ),
            );
          },
        );
      },
    );
  }
}
