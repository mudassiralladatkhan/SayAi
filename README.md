<div align="center">

# 🗣️ SayAi (SayNote AI)

### Voice-First AI Life Assistant for India

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth+Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green?style=for-the-badge)](.)

<br/>

**Your AI-powered voice companion — task management, voice journaling, AI conversations, smart reminders, and payments. Built for Indian users with Hinglish support.**

[Features](#-features) · [Architecture](#-architecture) · [Setup](#-setup) · [App Flow](#-app-flow)

---

</div>

## 🎯 What is SayAi?

SayAi is a cross-platform voice-first assistant that combines:
- 🎙️ **Voice capture** — speak naturally in Hindi/English, AI organizes your thoughts
- 🧠 **AI conversations** — Groq-powered (LLaMA 3 70B) contextual chat with personality modes
- ✅ **Smart task management** — voice-to-task with deadline detection and streak tracking
- 📓 **Voice diary** — daily journaling with mood analysis and night check-ins
- ⏰ **Intelligent alarms** — TTS-powered personalized wake-up calls
- 💰 **Razorpay subscriptions** — premium tier with Indian payment rails
- 🔒 **Biometric security** — fingerprint/face unlock via `local_auth`

---

## ✨ Features

| Feature | Implementation |
|---------|---------------|
| 🎤 Voice Input | `speech_to_text` with Hindi/English/Hinglish support |
| 🔊 Voice Output | `flutter_tts` with natural speech synthesis |
| 🤖 AI Chat (YOG) | Groq API (LLaMA 3 70B) with personality modes: Chill Yaar, Strict Coach, Funny Bestie |
| 📋 Task Manager | Provider state + Firebase Firestore persistence + streak tracking |
| 📓 Voice Diary | Audio capture → transcription → mood tagging |
| 🌙 Night Check-in | Guided evening reflection and mood journaling |
| ⏰ Smart Alarms | `android_alarm_manager_plus` + personalized TTS wake-up |
| 👤 User Profiles | Firebase Auth (Email + Google Sign-In) |
| 💳 Payments | Razorpay Flutter SDK for premium subscriptions |
| 🔔 Notifications | Firebase Cloud Messaging + Local Notifications |
| 🎁 Referral System | Invite tracking with reward points |
| 🔒 Biometric Auth | `local_auth` fingerprint/face unlock |
| 🎨 Onboarding | Animated Lottie-powered first-run experience |
| 🌐 Multi-language | Hindi, English, and Hinglish support |

---

## 🏗️ Architecture

```
lib/
├── main.dart                     # App entry, Firebase init, auth routing
├── models/                       # Data models (TaskModel, etc.)
├── providers/
│   └── task_provider.dart        # State management + Firestore sync
├── screens/
│   ├── home_screen.dart          # Main hub
│   ├── voice_capture_screen.dart # Voice input UI
│   ├── voice_diary_screen.dart   # Daily journal
│   ├── conversation_screen.dart  # AI chat with YOG
│   ├── alarm_screen.dart         # Alarm management
│   ├── schedule_screen.dart      # Calendar view
│   ├── night_checkin_screen.dart # Evening reflection
│   ├── pricing_screen.dart       # Subscription plans
│   ├── profile_screen.dart       # User settings & streaks
│   ├── referral_screen.dart      # Invite friends
│   ├── addon_screen.dart         # Premium add-ons
│   ├── settings_screen.dart      # App configuration
│   ├── auth_screen.dart          # Login/signup
│   └── onboarding_screen.dart    # First-run walkthrough
├── services/
│   ├── gpt_service.dart          # Groq/LLaMA 3 integration
│   ├── stt_service.dart          # Speech-to-text
│   ├── tts_service.dart          # Text-to-speech
│   ├── firebase_service.dart     # Firestore operations
│   ├── razorpay_service.dart     # Payment processing
│   ├── payment_service.dart      # Subscription management
│   ├── notification_service.dart # Push & local notifications
│   ├── alarm_service.dart        # Alarm scheduling
│   ├── referral_service.dart     # Referral tracking
│   └── user_service.dart         # Profile, streak & analytics
├── theme/
│   └── app_theme.dart            # Material 3 theming
└── widgets/                      # Reusable UI components
```

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.2+ (Android, iOS, Web) |
| Language | Dart |
| AI Backend | Groq API (LLaMA 3 70B) |
| Auth | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore |
| Local Storage | SharedPreferences |
| Voice | `speech_to_text` + `flutter_tts` |
| Payments | Razorpay Flutter SDK |
| Notifications | FCM + `flutter_local_notifications` |
| Alarms | `android_alarm_manager_plus` |
| Animations | Lottie |
| Security | `local_auth` (biometrics) |
| Screenshots | `screenshot` + `share_plus` |

---

## 🚀 Setup

### Prerequisites
- Flutter SDK 3.2+
- Firebase project configured
- Groq API key
- Android Studio / Xcode

### Installation

```bash
git clone https://github.com/mudassiralladatkhan/SayAi.git
cd SayAi

# Create .env file
echo "GROQ_API_KEY=your_groq_api_key_here" > .env

# Add Firebase config
# Place google-services.json in android/app/

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password + Google
3. Enable **Cloud Firestore**
4. Download `google-services.json` → `android/app/`
5. Add your **SHA-1 fingerprint** to Firebase Android app
6. Enable **Firebase Cloud Messaging** for push notifications

---

## 📱 App Flow

```
Splash → Auth (Email/Google) → Onboarding → Home
                                              ├── 🎤 Voice Capture (record → transcribe → action)
                                              ├── 🤖 AI Chat with YOG (3 personality modes)
                                              ├── ✅ Tasks (voice-created, streak-tracked)
                                              ├── 📓 Voice Diary (daily entries)
                                              ├── ⏰ Alarms & Schedule
                                              ├── 🌙 Night Check-in (evening reflection)
                                              ├── 💳 Pricing & Add-ons
                                              └── 👤 Profile (streaks, referrals, settings)
```

---

## 🎯 Target Users

- 🇮🇳 Indian users comfortable with voice input
- Professionals wanting voice-first productivity
- Users who prefer speaking over typing
- Hindi + English bilingual speakers
- Students needing task/schedule management

---

## 🤖 YOG Personality Modes

| Mode | Vibe |
|------|------|
| 😎 **Chill Yaar** | Casual, supportive, friend-like |
| 🏋️ **Strict Coach** | Direct, disciplined, accountability |
| 😂 **Funny Bestie** | Humorous, lighthearted, encouraging |

---

<div align="center">

**Built with 🗣️ by [Mudassir Alladatkhan](https://github.com/mudassiralladatkhan)**

*Speak your mind. Let AI handle the rest.*

</div>
