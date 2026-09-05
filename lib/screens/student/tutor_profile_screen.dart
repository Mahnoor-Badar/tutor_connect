
import 'package:flutter/material.dart';
import '../../models/tutor_profile.dart';
import '../booking_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  final TutorProfile tutor;

  const TutorProfileScreen({
    super.key,
    required this.tutor,
  });

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Tutor Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        child: Column(
          children: [
            // =====================================================
            // PROFILE HEADER
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor:
                        primaryColor,
                    backgroundImage:
                        tutor.photoUrl.isNotEmpty
                            ? NetworkImage(tutor.photoUrl)
                            : null,
                    child: tutor.photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: primaryColor,
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    tutor.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  if (tutor.city.isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tutor.city,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 19,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tutor.avgRating
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${tutor.reviewCount} reviews',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // ABOUT
            // =====================================================

            _InfoCard(
              icon: Icons.person_outline_rounded,
              title: 'About Tutor',
              child: Text(
                tutor.bio.isNotEmpty
                    ? tutor.bio
                    : 'No bio available.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =====================================================
            // SUBJECTS
            // =====================================================

            _InfoCard(
              icon: Icons.menu_book_outlined,
              title: 'Teaching Subjects',
              child: tutor.subjects.isEmpty
                  ? Text(
                      'No subjects listed.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          tutor.subjects.map((subject) {
                        return Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor
                                ,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            subject,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 16),

            // =====================================================
            // AVAILABILITY
            // =====================================================

            if (tutor.availableDays.isNotEmpty ||
                tutor.availableFrom.isNotEmpty ||
                tutor.availableTo.isNotEmpty)
              _InfoCard(
                icon: Icons.calendar_month_outlined,
                title: 'Teaching Availability',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (tutor.availableDays.isNotEmpty)
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children:
                            tutor.availableDays.map(
                          (day) {
                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey
                                    ,
                                borderRadius:
                                    BorderRadius.circular(
                                        9),
                              ),
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                    if (tutor.availableFrom.isNotEmpty &&
                        tutor.availableTo.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 19,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${tutor.availableFrom} - ${tutor.availableTo}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 26),

            // =====================================================
            // BOOK BUTTON
            // =====================================================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingScreen(
                        tutor: tutor,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Book a Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// REUSABLE INFORMATION CARD
// ===============================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  static const Color primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius:
                      BorderRadius.circular(11),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }
}

