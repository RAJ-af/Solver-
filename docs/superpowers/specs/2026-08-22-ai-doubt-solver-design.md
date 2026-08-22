# AI Doubt Solver — Design Spec

**Date:** 2026-08-22
**Status:** Approved (with image-compression amendment)

## Overview

Ek Flutter app jisme student kisi bhi question (math, science, etc.) ki photo
click karke ya gallery se select karke **step-by-step Hinglish solution** paata
hai. Solution kisi bhi **OpenAI-compatible vision API** se aata hai (default
config: OpenRouter, model `stealth/ox-alpha`) — provider `.env` me badla ja
sakta hai, code touch kiye bina. Response markdown me render hota hai, aur
locally save hota hai taaki baad me dobara dekha ja sake.

**Non-goals (YAGNI):** login/cloud sync, multiple subjects UI, OCR-only mode,
share buttons, chat-style follow-up questions.

## Architecture

Lightweight layered — plain Dart services + ek chhota `ChangeNotifier` store.
Koi codegen, koi BLoC nahi.

```
lib/
├── main.dart                ← dotenv init, MaterialApp, theme wiring
├── theme/app_theme.dart     ← light + dark ThemeData, text themes
├── models/doubt.dart        ← Doubt model
├── services/
│   ├── api_service.dart     ← OpenAI-compatible request/response (provider-agnostic)
│   ├── db_service.dart      ← sqflite CRUD
│   └── image_service.dart   ← resize/compress + persist processed file
├── store/doubt_store.dart   ← ChangeNotifier: doubts list + refresh triggers
├── screens/
│   ├── root_shell.dart      ← NavigationBar, 2 tabs (Solve | History), IndexedStack
│   ├── solve_tab.dart       ← hero, tagline, Camera / Gallery buttons
│   ├── solution_screen.dart ← analyzing state → result state
│   ├── detail_screen.dart   ← saved doubt ka full view (+ delete)
│   └── history_tab.dart     ← list of past doubts + empty state
└── widgets/
    ├── shimmer_skeleton.dart    ← loading skeleton blocks
    ├── doubt_card.dart          ← history list card
    └── empty_history.dart       ← empty-state composition
```

### Data flow

1. SolveTab par photo pick (camera ya gallery) → `ImageService.process()`
2. Processed file path ke saath `SolutionScreen` push hota hai (custom
   slide+fade route transition)
3. `SolutionScreen` initState me `ApiService.solve(path)` call:
   - processed file ko base64 encode karke OpenRouter ko bhejta hai
   - response se title + markdown solution parse hota hai
4. Success par auto-save (`DoubtStore.save`) → History tab refresh ho jata hai
5. Failure par error card + Retry button

## Image pipeline (amendment ke saath)

`ImageService.process(XFile source) -> Future<String> newPath`:

1. Decode: `dart:ui` `instantiateImageCodec(targetWidth: ≤1024)` — native
   decoder fast hai, aspect ratio preserve hota hai, chhoti images upscale nahi
   hoti
2. Pixels nikaalo: `ui.Image.toByteData(format: rawRgba)`
3. Encode: `image` package (pure Dart) se `encodeJpg(quality: 80)` — dart:ui ka
   ImageByteFormat sirf PNG deta hai jo photos ke liye bahut bada hota hai;
   `image` package se hum exact JPEG quality control paate hain aur encoder
   unit-testable bhi hai
4. File app documents dir me `<timestamp>_<random>.jpg` naam se save
5. Yehi ek file teeno jagah use hoti hai:
   - **API payload**: isi file ka base64 (`data:image/jpeg;base64,...`)
   - **History thumbnail**: chhota widget me fit render
   - **Detail view**: full-width render
6. Original camera file copy NAHI hoti — storage bachta hai

Target: typical phone photo 3–4 MB → ~150–350 KB processed.

## API contract (OpenAI-compatible chat completions)

Provider-agnostic: URL, key aur model teeno `.env` se aate hain — code me kahin
bhi hardcode nahi. Default config OpenRouter hai, par koi bhi OpenAI-compatible
endpoint chal jayega.

- Endpoint: `POST $API_BASE_URL` (default:
  `https://openrouter.ai/api/v1/chat/completions`)
- Headers: `Authorization: Bearer $API_KEY`, `Content-Type: application/json`
- Body:
  ```json
  {
    "model": "$API_MODEL",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "<prompt>"},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
      ]
    }]
  }
  ```
- Compatibility note: `image_url` simple object hi bhejte hain (`{"url": ...}`),
  optional fields like `detail` nahi bhejte — ye sabse zyada providers accept
  karte hain. Provider-specific extras ki zaroorat pade to wo future me add
  honge.
- Response parse: standard shape `choices[0].message.content` (string).
- Prompt (Hinglish instruction): pehli line exactly `TITLE: <chhota question>`
  (max ~60 chars), uske baad step-by-step Hinglish solution markdown me — har
  step numbered, formulas LaTeX ($...$) me, end me **Final Answer** section.
- Parsing: content agar `TITLE:` prefix se shuru hota hai to title split,
  warna fallback title = solution ka first non-empty line truncated 60 chars.
- Timeout: 90s. Errors: missing env values / SocketException / HTTP != 200 /
  malformed JSON → typed exceptions jo SolutionScreen friendly Hinglish error
  card dikhata hai (Retry ke saath).

## Local DB (sqflite)

Table `doubts`:

| Column       | Type    | Notes                          |
|--------------|---------|--------------------------------|
| id           | INTEGER | PK AUTOINCREMENT               |
| image_path   | TEXT    | processed file ka absolute path|
| title        | TEXT    | parsed short question          |
| solution     | TEXT    | full markdown                  |
| created_at   | INTEGER | epoch ms                       |

- DB name: `doubts.db`, version 1
- Delete: row delete + corresponding file delete
- App start / tab switch par `DoubtStore.refresh()` re-query karti hai

## Visual identity

### Colors

| Token            | Light                    | Dark                     |
|------------------|--------------------------|--------------------------|
| primary          | `#00BCC8` teal-cyan      | `#00BCC8` (glow accents) |
| secondary/accent | `#D0FF00` lime           | `#D0FF00` lime           |
| background       | `#F6FAFB` off-white      | `#0A0E13` deep blue-black|
| surface/card     | white                    | `#131920`                |
| onSurface        | `#0E1A1C`                | `#E8EFF0`                |
| muted text       | `#5A6B6E`                | `#8FA3A6`                |
| error            | `#E5484D`                | `#FF6369`                |

Dark mode sirf invert nahi — deep blue-black base, teal glow borders/gradients,
lime sirf success/sparkle moments pe.

### Typography

Google Fonts: headings **Sora** (SemiBold/Bold), body **Inter** (Regular/Medium).
Base body size 15, headings scale 20–28.

### Motion & states

- Tab switch: NavigationBar default + subtle fade via IndexedStack
- Photo pick → SolutionScreen: custom PageRouteBuilder (slide-up + fade, 300ms
  curved)
- Analyzing: selected photo preview + shimmer skeleton blocks + rotating status
  messages ("Photo padh rahe hain…", "Steps banaye ja rahe hain…", "Ox Alpha soch
  raha hai…") har ~2s
- Result: content fade+slide-in
- Empty history: custom icon composition (photo + sparkle motif), message +
  CTA button jo Solve tab pe le jaye
- Cards: 20px radius, soft shadow (light) / subtle border (dark)

## Android configuration

- `minSdk`: flutter default (24), target latest stable
- Permissions: `CAMERA` only — storage ki zaroorat nahi (image_picker modern
  system Photo Picker use karta hai)
- `<queries>` declarations for camera intent (image_picker README ke mutabik)
- App label: "AI Doubt Solver"

## Environment / secrets

`.env` (gitignored):

```env
API_BASE_URL=https://openrouter.ai/api/v1/chat/completions
API_KEY=yahan_apna_key_daalo
API_MODEL=stealth/ox-alpha
```

- Teeno values `ApiService` runtime par dotenv se read karta hai — provider
  switch karna ho to sirf `.env` edit, code change zero
- `.env.example` committed with placeholder values
- pubspec assets me `.env` registered; `main()` me `await dotenv.load()`
- Koi value na mile to app chalega, bas solve attempt par clear error message

## Packages (pubspec)

```yaml
dependencies:
  flutter_dotenv: ^6.x
  image_picker: ^1.x
  sqflite: ^2.x
  path: ^1.9.x
  provider: ^6.x
  google_fonts: ^6.x
  gpt_markdown: latest   # flutter_markdown discontinued; LaTeX support built-in
  http: ^1.x
  image: ^4.x            # sirf JPEG encode ke liye (quality control)
dev_dependencies:
  flutter_test, flutter_lints
```

(Exact versions `flutter pub add` se resolve honge.)

## CI — .github/workflows/build-apk.yml

Trigger: push on any branch.

1. checkout
2. `actions/setup-java@v4` Temurin 17
3. `subosito/flutter-action@v2` channel: stable, cache: true
4. `flutter pub get`
5. `flutter analyze` (fail CI on issues)
6. `flutter test`
7. `flutter build apk --release`
8. `actions/upload-artifact@v4`: `app-release.apk` → artifact name
   `ai-doubt-solver-apk`, retention 30 days

Note: CI me `.env` nahi hoga (secret gitignored hai) — build phir bhi pass hogi
kyunki dotenv load runtime cheez hai, compile-time nahi. (Optional improvement
baad me: repo secret se CI .env generate karna.)

## Testing strategy

- **Unit**: `DbService` (in-memory sqflite via `sqflite_common_ffi`),
  `ApiService` (mocked http — TITLE parse, error mapping, request body shape)
- **Widget**: SolveTab renders, HistoryTab empty vs filled, NavigationBar switch
- **Manual/local verify**: Flutter install ho chuka hai — `flutter build apk
  --release` yahin chala kar APK nikalne ka confirm karenge

## Milestones (implementation plan in details)

1. Scaffold + theme + navigation shell
2. Image service + permissions
3. API service + solution screen (analyzing → result)
4. DB + store + auto-save
5. History tab + detail screen + empty state
6. Polish (transitions, dark-mode audit) + tests
7. CI workflow + local release build verify
