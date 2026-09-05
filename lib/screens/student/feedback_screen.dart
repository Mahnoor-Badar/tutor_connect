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

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F7FC);

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
      final reviewId = '${user.uid}_${widget.session.tutorId}';

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
          _commentController.text = data['comment'] ?? '';
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
      final reviewId =
          '${user.uid}_${widget.session.tutorId}';

      final reviewRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId);

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
      backgroundColor: backgroundColor,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Session Feedback',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: _isLoadingFeedback
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // SESSION HEADER CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: primaryColor,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.subject,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.session.date.day}/'
                                    '${widget.session.date.month}/'
                                    '${widget.session.date.year}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.session.time,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // EXISTING FEEDBACK
                  // ==================================================

                  if (_feedbackExists)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin:
                          const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 25,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Feedback Submitted',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You have already submitted feedback for this tutor.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // RATING CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'How was your session?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Rate your learning experience',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) {
                              final starNumber = index + 1;

                              return IconButton(
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
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                icon: Icon(
                                  starNumber <= _rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 43,
                                  color: starNumber <= _rating
                                      ? Colors.amber
                                      : Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _rating == 0
                              ? 'Select a rating'
                              : '$_rating out of 5 stars',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _rating == 0
                                ? Colors.grey
                                : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // REVIEW CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              color: primaryColor,
                              size: 22,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Your Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Share your experience with this tutor',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: _commentController,
                          enabled:
                              !_feedbackExists &&
                              !_isSubmitting,
                          maxLines: 6,
                          textInputAction:
                              TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText:
                                'Write your feedback about the tutor...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                            contentPadding:
                                const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // SUBMIT BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed:
                          _feedbackExists ||
                                  _isSubmitting
                              ? null
                              : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        disabledForegroundColor:
                            Colors.grey.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _feedbackExists
                                  ? Icons.check_circle_outline
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting...'
                            : _feedbackExists
                                ? 'Feedback Submitted'
                                : 'Submit Feedback',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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