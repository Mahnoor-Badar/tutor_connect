import 'package:flutter/material.dart';

class MySessionsScreen extends StatelessWidget {
  const MySessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Your Sessions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _SessionCard(
            tutorName: 'Ahmed Khan',
            subject: 'Mathematics',
            date: '10/09/2026',
            time: '4:00 PM',
            status: 'Pending',
          ),

          const SizedBox(height: 12),

          _SessionCard(
            tutorName: 'Sara Ali',
            subject: 'Programming',
            date: '12/09/2026',
            time: '6:00 PM',
            status: 'Accepted',
          ),

          const SizedBox(height: 12),

          _SessionCard(
            tutorName: 'Usman Ahmed',
            subject: 'Physics',
            date: '05/09/2026',
            time: '3:00 PM',
            status: 'Declined',
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String tutorName;
  final String subject;
  final String date;
  final String time;
  final String status;

  const _SessionCard({
    required this.tutorName,
    required this.subject,
    required this.date,
    required this.time,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subject),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(),
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
                Text(date),

                const SizedBox(width: 20),

                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(time),
              ],
            ),
          ],
        ),
      ),
    );
  }
}