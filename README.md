# 🧠 planMee – AI-Powered Daily Task Manager
**CSC 660/680 App Design Project**

## 👥 Group Members
- Gabriel Fernandez (fernandezgabriel0@gmail.com)

---

## 📝 Project Proposal

**planMee** is a smart task manager built with SwiftUI that helps users structure their day efficiently using AI. Instead of simply listing tasks, users will input key details like estimated time, urgency, location sensitivity, and optional location info. The app will then generate an optimized, traffic-aware schedule to maximize time and minimize stress.

### 🎯 Core Concept:
> Enter your tasks → Tell planMee how long they take → AI builds the most efficient day for you.

---

## ✅ Must-Have Features
- Create, edit, and delete tasks
- Set time estimate per task
- Mark task as **location-sensitive** (vs. anywhere)
- Set urgency level (Low / Medium / High)
- Divide tasks into “Be Somewhere” and “Do Anywhere”
- Optional location entry (for “Be Somewhere” tasks)
- AI-generated task schedule using:
  - Time estimates
  - Urgency level
  - Fixed-time requirements
  - (Mocked) traffic/congestion data
- Store task data using CoreData or Firebase
- SwiftUI-based UI with multiple screens (task input, overview, schedule view)

---

## 🎁 Nice-to-Have Features
- Real traffic API integration (e.g., Apple Maps or Google Maps)
- Smart notifications: “Leave in 10 mins to avoid traffic”
- Dark/light mode toggle
- Natural language input (e.g., “Gym at 6pm, takes 1hr” → auto-parsed)
- “Schedule me” button that regenerates the day if something changes
- Weekly stats: total time spent, completed tasks, etc.
- Optional Apple Calendar sync
- AI voice assistant (e.g., “What’s my day looking like?”)

---

## 🖼️ Basic Wireframes
> *(Hand-drawn or Figma screenshots go here — just insert them in your repo and link or drag into the README)*

1. **Task Entry Screen**
   - Text field for task name
   - Time estimate picker
   - Toggle for “Must be at a certain time”
   - Location entry (if relevant)
   - Urgency level picker

2. **Task List View**
   - Two tabs: “Be Somewhere” & “Do Anywhere”
   - List of tasks with tags/indicators for urgency, time, and location

3. **Smart Day Plan View**
   - Shows AI-generated schedule
   - Timestamps, task blocks
   - Highlights traffic-sensitive areas

4. **Settings/Profile**
   - Toggle location permission
   - Customize urgency color scheme

---

## 🛠 Tech Stack
- **SwiftUI** (main UI)
- **CoreData** or **Firebase** (task storage)
- (Optional) Apple Maps or Google Maps SDK
- Custom AI logic (mocked traffic optimization)
