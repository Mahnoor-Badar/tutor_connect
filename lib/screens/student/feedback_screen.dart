import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/booking.dart';

class FeedbackScreen extends StatefulWidget {
  final Booking session;

  const FeedbackScreen({
    super.key,
    required this.session,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();

  int _rating = 0;

  bool _isSubmitting = false;
  bool _isLoadingFeedback = true;
  bool _feedbackExists = false;

  @override
  void initState() {
    super.initState();

    _loadExistingFeedback();
  }

  // ============================================================
  // LOAD EXISTING FEEDBACK
  // ============================================================

  Future<void> _loadExistingFeedback() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingFeedback = false;
        });
      }
      return;
    }

    try {
      // Same ID that we use when creating the review.
      final reviewId =
          '${user.uid}_${widget.session.tutorId}';

      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId);

      final reviewSnapshot = await reviewRef.get();

      if (!mounted) return;

      if (reviewSnapshot.exists) {
        final data =
            reviewSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _feedbackExists = true;

          _rating = (data['rating'] ?? 0) as int;

          _commentController.text =
              data['comment'] ?? '';

          _isLoadingFeedback = false;
        });
      } else {
        setState(() {
          _feedbackExists = false;
          _isLoadingFeedback = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFeedback = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load previous feedback: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT FEEDBACK
  // ============================================================

  Future<void> _submitFeedback() async {
    final comment = _commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first.'),
        ),
      );
      return;
    }

    if (_feedbackExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have already given feedback to this tutor.',
          ),
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating.'),
        ),
      );
      return;
    }

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ----------------------------------------------------------
      // Unique review ID:
      // One student + one tutor = one review.
      // ----------------------------------------------------------

      final reviewId =
          '${user.uid}_${widget.session.tutorId}';

      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId);

      // Check again before saving.
      // This protects against duplicate submissions.
      final existingReview = await reviewRef.get();

      if (existingReview.exists) {
        if (!mounted) return;

        setState(() {
          _feedbackExists = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already given feedback to this tutor.',
            ),
          ),
        );

        return;
      }

      await reviewRef.set({
        'studentId': user.uid,
        'tutorId': widget.session.tutorId,
        'bookingId': widget.session.id,
        'rating': _rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _feedbackExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Feedback submitted successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit feedback: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Feedback'),
      ),
      body: _isLoadingFeedback
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // SESSION SUBJECT
                  // ------------------------------------------------

                  Text(
                    widget.session.subject,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${widget.session.date.day}/'
                    '${widget.session.date.month}/'
                    '${widget.session.date.year} • '
                    '${widget.session.time}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // ALREADY SUBMITTED MESSAGE
                  // ------------------------------------------------

                  if (_feedbackExists)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin:
                          const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have already submitted feedback for this tutor.',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ------------------------------------------------
                  // RATING
                  // ------------------------------------------------

                  const Text(
                    'How was your session?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) {
                        final starNumber = index + 1;

                        return IconButton(
                          // Disable rating changes if feedback
                          // already exists.
                          onPressed:
                              _feedbackExists ||
                                      _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _rating =
                                            starNumber;
                                      });
                                    },
                          icon: Icon(
                            starNumber <= _rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      _rating == 0
                          ? 'Select a rating'
                          : '$_rating out of 5 stars',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // COMMENT
                  // ------------------------------------------------

                  const Text(
                    'Your Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _commentController,

                    // Disable editing after feedback exists.
                    enabled:
                        !_feedbackExists &&
                        !_isSubmitting,

                    maxLines: 6,

                    decoration: InputDecoration(
                      hintText:
                          'Write your feedback about the tutor...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // SUBMIT BUTTON
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          _feedbackExists ||
                                  _isSubmitting
                              ? null
                              : _submitFeedback,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _feedbackExists
                                  ? Icons.check
                                  : Icons.send,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting...'
                            : _feedbackExists
                                ? 'Feedback Submitted'
                                : 'Submit Feedback',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}