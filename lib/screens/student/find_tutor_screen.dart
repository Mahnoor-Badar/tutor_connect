import 'package:flutter/material.dart';
import '../../models/tutor_profile.dart';
import 'tutor_profile_screen.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<TutorProfile> _tutors = [
    TutorProfile(
      uid: 'tutor1',
      name: 'Ali Khan',
      bio: 'Experienced mathematics tutor.',
      subjects: ['Mathematics'],
      city: 'Lahore',
      photoUrl: '',
      avgRating: 4.8,
      reviewCount: 12,
    ),
    TutorProfile(
      uid: 'tutor2',
      name: 'Sara Ahmed',
      bio: 'Programming tutor specializing in Flutter and Dart.',
      subjects: ['Programming', 'Flutter'],
      city: 'Islamabad',
      photoUrl: '',
      avgRating: 4.7,
      reviewCount: 9,
    ),
    TutorProfile(
      uid: 'tutor3',
      name: 'Ahmed Raza',
      bio: 'Physics tutor for school and university students.',
      subjects: ['Physics'],
      city: 'Karachi',
      photoUrl: '',
      avgRating: 4.9,
      reviewCount: 15,
    ),
  ];

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  List<TutorProfile> get _filteredTutors {
    if (_searchText.isEmpty) {
      return _tutors;
    }

    return _tutors.where((tutor) {
      final name = tutor.name.toLowerCase();
      final subjects = tutor.subjects.join(' ').toLowerCase();
      final city = tutor.city.toLowerCase();

      return name.contains(_searchText) ||
          subjects.contains(_searchText) ||
          city.contains(_searchText);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutors = _filteredTutors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Tutor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tutor, subject or city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Available Tutors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: tutors.isEmpty
                  ? const Center(
                      child: Text(
                        'No tutors found.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tutors.length,
                      itemBuilder: (context, index) {
                        return _TutorCard(
                          tutor: tutors[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final TutorProfile tutor;

  const _TutorCard({
    required this.tutor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: tutor.photoUrl.isNotEmpty
                  ? NetworkImage(tutor.photoUrl)
                  : null,
              child: tutor.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutor.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    tutor.subjects.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 18),
                      const SizedBox(width: 4),
                      Text(tutor.avgRating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Text(
                        tutor.city,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorProfileScreen(
                      tutor: tutor,
                    ),
                  ),
                );
              },
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}