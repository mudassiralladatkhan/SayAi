# SayNote AI 🎙️

> Your voice-first AI life companion for Indian users — powered by Groq & LLaMA 3.

---

## Features

- 🎙️ **Voice-first interface** — speak to YOG, your personal AI assistant
- ✅ **Smart task management** — add, complete, and delete tasks via voice or text
- 🔥 **Streak tracking** — stay consistent with daily productivity streaks
- ⏰ **Alarm & reminders** — personalized TTS wake-up alarms
- 📓 **Night check-in** — daily mood & reflection diary
- 🤖 **YOG personality** — choose Chill Yaar, Strict Coach, or Funny Bestie mode
- 🌐 **Hinglish, Hindi & English** — talk to YOG in your preferred language
- ☁️ **Cloud sync** — all data synced to Firebase Firestore across devices
- 🔐 **Authentication** — Email/Password + Google Sign-In via Firebase Auth

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| AI Backend | Groq API (LLaMA 3 70B) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Local Storage | SharedPreferences |
| Notifications | flutter_local_notifications |
| TTS | flutter_tts |
| STT | speech_to_text |

---

## Setup

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Firebase project with Android app configured
- Groq API key

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/mudassiralladatkhan/SayAi.git
   cd SayAi
   ```

2. **Add your secrets**
   - Create `.env` in the project root:
     ```
     GROQ_API_KEY=your_groq_api_key_here
     ```
   - Add `android/app/google-services.json` from your Firebase Console

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run**
   ```bash
   flutter run
   ```

---

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password + Google
3. Enable **Cloud Firestore**
4. Download `google-services.json` and place in `android/app/`
5. Add your **SHA-1 fingerprint** to the Firebase Android app

---

## Architecture

```
lib/
├── main.dart              # App entry + Firebase init + routing
├── theme/                 # AppTheme constants
├── models/                # TaskModel
├── providers/             # TaskProvider (state + Firestore sync)
├── services/              # GPT, Notification, UserService
├── screens/               # All app screens
└── widgets/               # Reusable UI components
```

---

*Built with ❤️ for India*
