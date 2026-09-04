import 'package:flutter/material.dart';
import '../../models/tutor_profile.dart';
import '../booking_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  final TutorProfile tutor;

  const TutorProfileScreen({
    super.key,
    required this.tutor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundImage: tutor.photoUrl.isNotEmpty
                  ? NetworkImage(tutor.photoUrl)
                  : null,
              child: tutor.photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 55)
                  : null,
            ),

            const SizedBox(height: 15),

            Text(
              tutor.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (tutor.city.isNotEmpty)
              Text(
                tutor.city,
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star),
                const SizedBox(width: 5),
                Text(
                  tutor.avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 5),
                Text(
                  '(${tutor.reviewCount} reviews)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Tutor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tutor.bio.isNotEmpty
                          ? tutor.bio
                          : 'No bio available.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teaching Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tutor.subjects.map((subject) {
                        return Chip(
                          label: Text(subject),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        tutor: tutor,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Book a Session',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}