# NeverThink – AI-Powered Daily Task Manager  
**CSC 660/680 App Design Project**

## IMPORTANT: SETTING UP THE PROJECT

To run the project properly, you'll need two API keys:

1. **OpenAI GPT Key** – Used for generating smart daily plans.
2. **Google Maps Directions API Key** – Used for calculating ETAs and travel durations.

### 🔑 Setup Instructions:
1. Open the **Google Doc**: https://docs.google.com/document/d/1BIY8AqZgmbGr-NoegbEY_yp4SmAwuksZKRM46LlOtsQ/edit?usp=sharing.
2. Copy both keys:
   - `OPENAI_API_KEY`
   - `GOOGLE_API_KEY`
3. In Xcode, open `ContentView.swift`.
4. Replace the placeholder keys in these lines:

**In `ContentView.swift`:**
```swift
PlannerService.shared.configure(apiKey: "OPENAI_API_KEY_HERE")
TravelService.shared.configure(apiKey: "GOOGLE_API_KEY_HERE")
```

---

## Programmer
- Gabriel Fernandez (9204899310@sfsu.edu) (Github: Gabrieln21)

---

## NeverThink Demo Video
- https://youtu.be/Xhsqc076kfo

---

## Project Summary

**NeverThink** is a productivity app designed to help users stop overthinking their schedules. Rather than just listing tasks, users provide structured duration, urgency, and location sensitivity—and the app uses **AI and real-time traffic data** to generate a daily plan that’s actually doable.

### Core Concept:
> You enter your tasks → NeverThink thinks for you → You follow the smartest version of your day.

---

## Features

### ✅ Must-Have Features (Implemented)
- [x] Add, edit, delete tasks
- [x] Set time estimate per task
- [x] Urgency levels (Low / Medium / High)
- [x] Location-sensitive task flag
- [x] Support for “Be Somewhere” vs. “Do Anywhere” categorization
- [x] Optional location input (address or saved place)
- [x] AI-generated schedule using:
  - Time estimates
  - Urgency
  - Fixed time constraints
  - Traffic-aware travel estimation (Google Maps)
- [x] AI rescheduling center (review, accept, or regenerate daily plans)
- [x] Recurring task support (Daily, Weekly, etc.)
- [x] Store all task data using **CoreData**
- [x] SwiftUI UI with multiple views (home, topics, recurring, settings)
- [x] Manual rescheduling with smart prompts

### ⭐ Nice-to-Have Features (Many implemented)
- [x] Google Maps Directions API for ETA calculation
- [x] Smart leave-time indicator based on travel time
- [x] button to schedule day on demand
- [x] Daily confetti celebration when tasks are completed
- [ ] Natural language task parsing (partially planned)
- [ ] Weekly stats (in future)
- [ ] Apple Calendar sync (future scope)
- [ ] Voice assistant support (somwhat already possible)

---

## Core Screens (Wireframes in Repo)

1. **Home View (Today’s Plan)**
   - Calendar picker
   - AI-generated and user tasks
   - Swipe to complete/reschedule
   - Add task button + confetti animations

2. **Task Entry & Editing**
   - Title, duration, urgency
   - Time sensitivity toggle (with smart options)
   - Location type (Home, Anywhere, Custom)
   - Category: Do Anywhere vs Be Somewhere

3. **AI Rescheduling Center**
   - See problematic/conflicting tasks
   - Select for AI optimization
   - Review and regenerate plans with notes

4. **Recurring Task Manager**
   - Add recurring tasks (daily/weekly/monthly/yearly)
   - Set smart rules for time/location/urgency

5. **Topic-Based Lists**
   - View all task groups
   - Group tasks by theme/project/topic
   - Edit individual task groups

6. **Settings View**
   - Change home address
   - View saved locations
   - Enable travel mode (driving, biking, walking)

---

## Tech Stack

| Layer        | Tech                          |
|--------------|-------------------------------|
| UI           | SwiftUI                       |
| Storage      | CoreData                      |
| AI Planner   | OpenAI GPT-4 (custom logic)   |
| Travel Time  | Google Maps Directions API    |
| Location     | CoreLocation / Custom Services|
| JSON Parsing | Foundation / Codable structs  |

---

## Architecture Notes

- `TaskGroupManager` stores all tasks grouped by topic or AI logic.
- `TodayPlanManager` controls AI-generated day plans.
- `RecurringTaskManager` handles auto-generated tasks.
- `PlannerService` builds prompt logic for OpenAI requests.
- `TravelService` estimates commute time using Google Maps.
- `LocationService` uses the device’s live location and saved addresses.

---

## Final Notes

This project represents the intersection of **AI task optimization, SwiftUI design**, and **real-world integration with travel data**. The goal is to build something users can rely on to take the thinking out of planning.

> “Don’t overthink your day. Let NeverThink do it for you.” 💭✨
