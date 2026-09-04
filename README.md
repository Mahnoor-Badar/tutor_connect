# Tutor Booking App

A comprehensive full-stack application designed to connect students with tutors, manage session bookings, handle reviews, and track payment transactions seamlessly.

---

 Work Distribution (50/50 Partition)

 Member A: Student Experience + Feedback

* **Authentication:** Login / Signup UI integrated with Firebase Auth.
* **Student Dashboard:** Personalized student welcome view displaying stats like upcoming lessons.
* **Find Tutor:** Search screen with Subject and City filters.
* **Tutor Profile:** View detailed tutor profiles, overall ratings, and student reviews.
* **Student Sessions:** Track sessions with tabs for Upcoming, History, and Cancelled.
* **Session Notes:** Notes UI equipped with an AI Summarizer tool.
* **Feedback System:** Full CRUD functionality (Create, Read, Update, Delete) for tutor reviews and ratings.
* **Payment Status:** Visual indicator displaying paid vs. unpaid session statuses.

Member B: Tutor Experience & Core Logic

* **Role Management:** Role selection logic integrated with Firestore `users` collection.
* **Tutor Dashboard:** Personalized control panel displaying upcoming bookings and analytics.
* **Tutor Profile CRUD:** Ability to Create, Edit, and Delete public tutor profile details.
* **Booking UI:** Interactive booking screen integrated with an external Holiday API.
* **Booking Backend:** Booking CRUD operations, Firestore logic, and double-booking prevention validation.
* **Tutor Sessions:** Manage incoming booking requests (Accept/Decline) with tutor custom messaging.
* **Security Rules:** Firestore security rules for all database collections.
* **Transaction & Payment Backend:** Logic to mark sessions as 'Paid' and create corresponding financial transaction records.

---

Shared Responsibilities

* Full-stack Integration
* UI Polish & Responsive Styling
* Bug Fixing & Testing
* Final Demo & Project Report Documentation

---

Tech Stack

* **Frontend:** Mobile/Web UI
* **Authentication & Database:** Firebase Auth, Google Cloud Firestore
* **APIs:** External Public Holiday API, AI Summarization Integration
* **Version Control:** Git / GitHub

---
Features Overview

1. **User Authentication & Role Assignment:** Secure login and registration routing users to either Student or Tutor environments.
2. **Smart Tutor Discovery:** Search tutors based on specific subject expertise and location filter criteria.
3. **Session Scheduling:** Real-time scheduling equipped with double-booking prevention and public holiday integration.
4. **AI-Powered Session Notes:** Summarize lesson key points automatically using built-in AI tools.
5. **Session Management:** Comprehensive request flows allowing tutors to accept or reject sessions.
6. **Ratings & Feedback:** Complete feedback management system for students to leave reviews.
7. **Payment & Financial Tracking:** Transparent status tracking (Paid/Unpaid) paired with automated transaction records.
