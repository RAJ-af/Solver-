<div align="center">

# 🎓 AI Doubt Solver

**Photo kheencho, doubt clear karo.** Snap your doubt — get a step-by-step Hinglish solution, powered by AI.

[![Build Release APK](https://github.com/RAJ-af/Solver-/actions/workflows/build-apk.yml/badge.svg)](https://github.com/RAJ-af/Solver-/actions/workflows/build-apk.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-00BCC8)

</div>

---

A student just points their camera at a question (or picks one from the gallery) and gets a clean, markdown-formatted **step-by-step solution in Hinglish** — every solved doubt is saved locally so it can be revisited anytime.

## ✨ Features

- 📷 **Camera / gallery input** — click a photo of your doubt or pick from gallery
- 🤖 **AI-powered solutions** — OpenAI-compatible vision API returns structured, step-by-step answers
- 🗣️ **Hinglish explanations** — solutions come back the way Indian students actually study
- 💾 **Local history** — every solve is saved with thumbnail + timestamp (sqflite); tap to reopen
- 🌙 **Polished dark mode** — hand-tuned dark palette (#0A0E13), not an inverted light theme
- ⚡ **Skeleton loaders & smooth transitions** — shimmer placeholders, slide-up routes, tab fade

## 🛠️ Tech Stack

| Layer | Tech |
|---|---|
| Framework | Flutter (Dart) |
| State | provider |
| Storage | sqflite |
| AI API | [OpenCode Zen](https://opencode.ai/zen) — `mimo-v2.5-free` model (OpenAI-compatible) |
| Config | flutter_dotenv (`.env`) — API key never hardcoded |
| UI | Material 3, google_fonts (Sora / Inter), gpt_markdown |

The app is **provider-agnostic**: any OpenAI-compatible chat-completions endpoint works — just change `API_BASE_URL` / `API_MODEL` in `.env`.

## 📸 Screenshots

> _Screenshots coming soon — drop images into `screenshots/` with these names._

| Solve | Solution | History |
|:---:|:---:|:---:|
| ![Solve screen](screenshots/solve.png) | ![Solution screen](screenshots/solution.png) | ![History screen](screenshots/history.png) |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.47+ (`flutter doctor` should be green for your platform)
- An API key from [OpenCode Zen](https://opencode.ai/zen) (or any OpenAI-compatible provider)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/RAJ-af/Solver-.git
cd Solver-

# 2. Create your .env
cp .env.example .env

# 3. Add your API key to .env
#    API_KEY=your_real_key_here

# 4. Install dependencies & run
flutter pub get
flutter run
```

`.env` reference:

```dotenv
API_BASE_URL=https://opencode.ai/zen/v1
API_KEY=your_real_key_here
API_MODEL=mimo-v2.5-free
```

## 📦 Release APK (CI/CD)

Every push triggers [GitHub Actions](.github/workflows/build-apk.yml), which runs analyze → tests → release build and uploads the APK as an artifact.

1. Open the repo's **Actions** tab
2. Click the latest **Build Release APK** run
3. Download **ai-doubt-solver-apk** from the Artifacts section

> CI builds use a placeholder `.env` — install your own key via step 3 of Setup for working API calls.

## 🧪 Tests

```bash
flutter test      # unit + widget tests
flutter analyze   # static analysis
```

## 🤝 Contributing

Issues and PRs welcome — keep PRs small and focused.

## 📄 License

Released under the [MIT License](LICENSE).
