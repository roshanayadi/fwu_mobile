# FWU Mobile - Complete Project Documentation

> **Far Western University (FWU) Exam Management Information System (EMIS) Mobile Application**
>
> A comprehensive Flutter-based mobile application that provides students of Far Western University, Nepal, with access to exam registration, result checking, payments, AI-powered support, and other university services.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture Overview](#3-architecture-overview)
4. [Folder Structure](#4-folder-structure)
5. [State Management](#5-state-management)
6. [Data Models](#6-data-models)
7. [Services Layer](#7-services-layer)
8. [Screens & Navigation](#8-screens--navigation)
9. [Components & Widgets](#9-components--widgets)
10. [API & Backend Integration](#10-api--backend-integration)
11. [Payment Gateway Integration](#11-payment-gateway-integration)
12. [AI Integration](#12-ai-integration)
13. [Security & Authentication](#13-security--authentication)
14. [Architecture Diagrams](#14-architecture-diagrams)
15. [Workflow Diagrams](#15-workflow-diagrams)
16. [Environment Configuration](#16-environment-configuration)
17. [Dependencies](#17-dependencies)
18. [Build & Deployment](#18-build--deployment)

---

## 1. Project Overview

### What is FWU Mobile?

FWU Mobile is a student portal application developed as a final year project for Far Western University. Since FWU does not provide a public REST API, this app authenticates via the university's web portal (`https://exam.fwu.edu.np`), maintains session cookies, and parses HTML/embedded JavaScript to extract student data.

### Key Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Login with registration number, biometric (fingerprint) login |
| **Dashboard** | Student info, quick services, notices, Nepali calendar |
| **Exam Registration** | Browse open exams, select subjects, submit forms |
| **Payments** | eSewa, Khalti, ConnectIPS, HBL payment gateways |
| **Results** | Check exam results, auto-detect latest result, print PDF |
| **Digital ID** | Digital student identity card |
| **AI Assistant** | Gemini/Groq powered chatbot for university queries |
| **Notifications** | University notices scraped from official website |
| **Syllabus** | Browse and download syllabuses for all programs |
| **Profile** | View and update profile photo/signature |
| **Academic Calendar** | Nepali Bikram Sambat calendar with events |

### Platform Support

- Android (Primary)
- iOS
- Web (Secondary)
- Windows/Linux/macOS (Desktop support scaffolded)

---

## 2. Technology Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart SDK ^3.11.3) |
| **State Management** | Provider (ChangeNotifier pattern) |
| **HTTP Client** | `http` package + `dart:io HttpClient` (for SSL bypass) |
| **Local Storage** | `shared_preferences` + `flutter_secure_storage` |
| **Authentication** | Session cookies + `local_auth` (biometrics) |
| **WebView** | `flutter_inappwebview` + `webview_flutter` |
| **AI Services** | Google Gemini API + Groq API (fallback) |
| **PDF** | `pdf` + `printing` packages |
| **Email** | SMTP via `mailer` package |
| **UI** | Material Design 3, Google Fonts (Inter), custom components |
| **Environment** | `flutter_dotenv` |

---

## 3. Architecture Overview

The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Screens  │  │ Widgets  │  │Components│  │   Dialogs    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │               │            │
├───────┼──────────────┼──────────────┼───────────────┼────────────┤
│       │         STATE MANAGEMENT LAYER              │            │
│       ▼              ▼              ▼               ▼            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    PROVIDERS                             │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │    │
│  │  │ AuthProvider │ │ResultProvider│ │ FormProvider │   │    │
│  │  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘   │    │
│  └─────────┼────────────────┼────────────────┼────────────┘    │
│            │                │                │                   │
├────────────┼────────────────┼────────────────┼───────────────────┤
│            │          DATA LAYER             │                   │
│            ▼                ▼                ▼                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                     MODELS                               │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │    │
│  │  │ StudentModel │ │ ResultModel  │ │  FormModel   │   │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                        SERVICES LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│  │GeminiService │  │ GroqService  │  │   SmtpService    │      │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘      │
│         │                  │                    │                 │
├─────────┼──────────────────┼────────────────────┼─────────────────┤
│         │           EXTERNAL SERVICES           │                 │
│         ▼                  ▼                    ▼                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│  │ Gemini API   │  │  Groq API    │  │   Gmail SMTP     │      │
│  └──────────────┘  └──────────────┘  └──────────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│  │FWU Exam EMIS │  │Payment Gates │  │ FWU Custom API   │      │
│  └──────────────┘  └──────────────┘  └──────────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

### Design Patterns Used

| Pattern | Usage |
|---------|-------|
| **Provider Pattern** | State management across the app |
| **ChangeNotifier** | Reactive UI updates |
| **Repository-like Providers** | Providers double as data access layer |
| **HTML Scraping** | No public API; parses web portal HTML |
| **Fallback Strategy** | Gemini -> Groq AI fallback chain |
| **Session-based Auth** | Cookie-based authentication with FWU portal |
| **Offline-first Caching** | Notices cached in SharedPreferences |

---

## 4. Folder Structure

```
fwu_mobile/
├── android/                          # Android native project
│   ├── app/
│   │   └── src/main/
│   │       └── AndroidManifest.xml   # Permissions: INTERNET, BIOMETRIC
│   └── ...
├── ios/                              # iOS native project
├── web/                              # Web support
├── windows/                          # Windows desktop support
├── linux/                            # Linux desktop support
├── macos/                            # macOS desktop support
│
├── assets/
│   ├── images/
│   │   ├── banner.jpg                # Dashboard hero banner
│   │   ├── bnr.jpeg                  # Secondary banner
│   │   ├── fwu_logo.png             # University logo
│   │   └── lokesh.jpg               # Developer photo
│   └── logo/
│       └── logo.png                  # App icon/splash logo
│
├── lib/                              # Main Dart source code
│   ├── main.dart                     # App entry point
│   ├── constants.dart                # Colors, config, base URLs
│   │
│   ├── models/                       # Data models
│   │   ├── student_model.dart        # StudentInfo model
│   │   ├── result_model.dart         # ExamResult, SubjectResult, ExamSchedule
│   │   └── form_model.dart           # ExamFormData, FormSubject, SubjectGroup
│   │
│   ├── providers/                    # State management (ChangeNotifiers)
│   │   ├── auth_provider.dart        # Authentication, profile, biometrics
│   │   ├── result_provider.dart      # Result fetching & parsing
│   │   └── form_provider.dart        # Form filling, payments, admit cards
│   │
│   ├── services/                     # External service integrations
│   │   ├── gemini_service.dart       # Google Gemini AI (primary)
│   │   ├── groq_service.dart         # Groq/Llama AI (fallback)
│   │   └── smtp_service.dart         # Email OTP service
│   │
│   ├── screens/                      # Full-page screens
│   │   ├── splash_screen.dart        # Initial loading & auth check
│   │   ├── login_screen.dart         # Login + Register tabs
│   │   ├── home_screen.dart          # Main shell with bottom nav
│   │   ├── dashboard_screen.dart     # Home tab content
│   │   ├── result_screen.dart        # Result lookup form
│   │   ├── result_display_screen.dart# Grade sheet display
│   │   ├── forms_screen.dart         # Exam form list
│   │   ├── form_fill_screen.dart     # Subject selection & submit
│   │   ├── payment_screen.dart       # Gateway selection
│   │   ├── payment_webview_screen.dart# Payment processing WebView
│   │   ├── notifications_screen.dart # Notices feed
│   │   ├── profile_screen.dart       # Student profile
│   │   ├── settings_screen.dart      # Settings hub
│   │   ├── syllabus_screen.dart      # Syllabus browser
│   │   ├── pdf_viewer_screen.dart    # In-app PDF/DOCX viewer
│   │   ├── no_internet_screen.dart   # Offline fallback
│   │   ├── app_guide_screen.dart     # How-to-use guide
│   │   │
│   │   ├── forgot_password/          # Password reset flow
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── otp_verification_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   │
│   │   ├── quick_actions/            # Quick service screens
│   │   │   ├── academic_calendar_screen.dart
│   │   │   ├── all_services_screen.dart
│   │   │   ├── digital_id_screen.dart
│   │   │   ├── quick_notices.dart
│   │   │   ├── quick_support.dart    # AI chatbot
│   │   │   └── quick_website.dart    # In-app browser
│   │   │
│   │   └── setting_widgets/          # Settings sub-screens
│   │       ├── change_password_screen.dart
│   │       ├── contact_about_screen.dart
│   │       ├── help_faq_screen.dart
│   │       ├── privacy_policy_screen.dart
│   │       └── terms_conditions_screen.dart
│   │
│   ├── widgets/                      # Reusable widgets
│   │   ├── connectivity_wrapper.dart # Global network monitor
│   │   ├── latest_update_card.dart   # Notice card with caching
│   │   ├── rate_us_card.dart         # Star rating widget
│   │   └── app_guide_section.dart    # Guide link row
│   │
│   ├── components/                   # Complex UI components
│   │   ├── floating_dock.dart        # Bottom navigation bar
│   │   └── floating_ai_bubble.dart   # Draggable AI FAB
│   │
│   ├── utils/                        # Utilities
│   │   └── pdf_generator.dart        # PDF marksheet generator
│   │
│   └── Tests/                        # Test scripts
│       ├── ssl_test.dart
│       └── test_fetch_script.dart
│
├── .env                              # Environment variables (API keys)
├── pubspec.yaml                      # Dependencies & project config
├── pubspec.lock                      # Locked dependency versions
├── analysis_options.yaml             # Linting rules
└── README.md                         # Basic readme
```

---

## 5. State Management

The app uses the **Provider** package with `ChangeNotifier` pattern for reactive state management.

### Provider Architecture

```
                    MultiProvider (main.dart)
                           │
              ┌────────────┼────────────────┐
              ▼            ▼                ▼
       AuthProvider   ResultProvider   FormProvider
       (Core Auth)    (Results)        (Forms/Pay)
              │            │                │
              ▼            ▼                ▼
       StudentInfo    ExamResult       ExamFormData
       Session        ExamSchedule[]   ExamSchedule[]
       Biometric      SubjectResult[]  FormSubject[]
```

### AuthProvider (auth_provider.dart)

**Responsibilities:**
- User login/logout with session management
- Profile fetching and parsing
- Biometric authentication
- Password change
- Profile photo/signature upload
- Contact info sync to custom server

**State fields:**
```dart
StudentInfo? studentInfo
String? sessionCookie
bool isAuthenticated
bool isLoading
bool isBiometricEnabled
String? errorMessage
```

### ResultProvider (result_provider.dart)

**Responsibilities:**
- Fetch published exam schedules
- Check individual student results
- Parse result data from HTML/JSON

**State fields:**
```dart
List<ExamSchedule> examSchedules
ExamResult? currentResult
bool isLoading
String? error
```

### FormProvider (form_provider.dart)

**Responsibilities:**
- Fetch exam schedules for registration
- Load and submit exam forms
- Handle payment gateway initiation
- Download admit cards

**State fields:**
```dart
List<ExamSchedule> examSchedules
ExamFormData? currentForm
bool isLoading
String? error
```

---

## 6. Data Models

### StudentInfo (student_model.dart)

```
┌────────────────────────────────────┐
│           StudentInfo               │
├────────────────────────────────────┤
│ + fullName: String                 │
│ + gender: String                   │
│ + dob: String                      │
│ + ethnicity: String                │
│ + contact: String                  │
│ + email: String                    │
│ + academicYear: String             │
│ + registrationNo: String           │
│ + faculty: String                  │
│ + college: String                  │
│ + address: String                  │
│ + bloodGroup: String               │
│ + nationality: String              │
│ + religion: String                 │
│ + category: String                 │
│ + photo: String? (base64/URL)      │
│ + signature: String? (base64/URL)  │
└────────────────────────────────────┘
```

### ExamResult (result_model.dart)

```
┌─────────────────────────────────┐
│          ExamResult              │
├─────────────────────────────────┤
│ + examName: String              │
│ + studentName: String           │
│ + symbolNo: String              │
│ + registrationNo: String        │
│ + campus: String                │
│ + faculty: String               │
│ + gpa: String                   │
│ + resultStatus: String          │
│ + subjects: List<SubjectResult> │
└─────────────┬───────────────────┘
              │ has many
              ▼
┌─────────────────────────────────┐
│        SubjectResult             │
├─────────────────────────────────┤
│ + subjectCode: String           │
│ + subjectName: String           │
│ + theoryInternal: String        │
│ + theoryExternal: String        │
│ + practicalInternal: String     │
│ + practicalExternal: String     │
│ + totalMarks: String            │
│ + gradePoint: String            │
│ + grade: String                 │
│ + result: String                │
└─────────────────────────────────┘
```

### ExamFormData (form_model.dart)

```
┌──────────────────────────────────────────┐
│            ExamFormData                    │
├──────────────────────────────────────────┤
│ + rawModel: Map<String, dynamic>         │
│ + pageType: String (examForm/payment)    │
│ + paymentInfo: Map (gateway settings)    │
│ + subjectGroups: List<SubjectGroup>      │
│ + amount: double                         │
└───────────────────┬──────────────────────┘
                    │ contains
                    ▼
┌──────────────────────────────────────────┐
│           SubjectGroup                    │
├──────────────────────────────────────────┤
│ + name: String                           │
│ + types: List<SubjectType>               │
└───────────────────┬──────────────────────┘
                    │ contains
                    ▼
┌──────────────────────────────────────────┐
│           SubjectType                     │
├──────────────────────────────────────────┤
│ + name: String                           │
│ + subjects: List<FormSubject>            │
└───────────────────┬──────────────────────┘
                    │ contains
                    ▼
┌──────────────────────────────────────────┐
│           FormSubject                     │
├──────────────────────────────────────────┤
│ + id: int                                │
│ + name: String                           │
│ + code: String                           │
│ + theorySelected: bool                   │
│ + practicalSelected: bool                │
│ + isCompulsory: bool                     │
└──────────────────────────────────────────┘
```

---

## 7. Services Layer

### GeminiService (gemini_service.dart)

**Primary AI service** with automatic failover to Groq.

```
┌─────────────────────────────────────────────────┐
│                GeminiService                      │
├─────────────────────────────────────────────────┤
│ - _apiKey: String (from .env)                   │
│ - _models: [gemini-3.1-flash-lite-preview]      │
│ - _timeout: 20s                                  │
│ - _maxRetries: 2                                 │
├─────────────────────────────────────────────────┤
│ + getChatCompletion(messages, context)           │
│ - _postWithRetry(model, body)                   │
│ - _handleResponse(response)                     │
├─────────────────────────────────────────────────┤
│ Fallback: GroqService on all models failing     │
│ System Prompt: FWU-only queries, navigation     │
│   buttons, notice summarization, result fetch   │
└─────────────────────────────────────────────────┘
```

### GroqService (groq_service.dart)

**Fallback AI service** using Llama model via OpenAI-compatible API.

```
┌─────────────────────────────────────────────────┐
│                 GroqService                       │
├─────────────────────────────────────────────────┤
│ - _apiKey: String (from .env)                   │
│ - _model: llama-3.3-70b-versatile               │
├─────────────────────────────────────────────────┤
│ + getChatCompletion(messages, context)           │
├─────────────────────────────────────────────────┤
│ API: https://api.groq.com/openai/v1/...         │
└─────────────────────────────────────────────────┘
```

### SmtpService (smtp_service.dart)

**Email OTP service** for password reset flow.

```
┌─────────────────────────────────────────────────┐
│                SmtpService                        │
├─────────────────────────────────────────────────┤
│ - smtpUser: String (from .env)                  │
│ - smtpPass: String (from .env)                  │
├─────────────────────────────────────────────────┤
│ + generateOtp() → String (6-digit)              │
│ + sendOtpEmail(email, otp) → bool               │
├─────────────────────────────────────────────────┤
│ Server: smtp.gmail.com:587 (TLS)                │
└─────────────────────────────────────────────────┘
```

---

## 8. Screens & Navigation

### Navigation Flow Diagram

```
                         App Start
                            │
                            ▼
                     ┌─────────────┐
                     │SplashScreen │
                     └──────┬──────┘
                            │
              ┌─────────────┼─────────────┐
              │ (not auth)  │             │ (authenticated)
              ▼             │             ▼
       ┌─────────────┐     │      ┌─────────────┐
       │ LoginScreen │     │      │ HomeScreen  │
       └──────┬──────┘     │      └──────┬──────┘
              │             │             │
              │   ┌─────────┘             │
              │   │                       │
              ▼   ▼                       ▼
       ┌──────────────────────────────────────────────────────┐
       │                    HomeScreen                         │
       │  ┌──────────────────────────────────────────────┐   │
       │  │              FloatingDock (5 tabs)            │   │
       │  └──────────────────────────────────────────────┘   │
       │                                                      │
       │  Tab 0: DashboardScreen                             │
       │  Tab 1: ResultScreen                                │
       │  Tab 2: FormsScreen                                 │
       │  Tab 3: NotificationsScreen                         │
       │  Tab 4: SettingsScreen                              │
       │                                                      │
       │  Overlay: FloatingAiBubble → QuickSupportScreen     │
       └──────────────────────────────────────────────────────┘
```

### Complete Screen Map

```
HomeScreen (Shell)
├── Tab 0: DashboardScreen
│   ├── → DigitalIdScreen
│   ├── → ResultScreen
│   ├── → FormsScreen
│   ├── → QuickWebsiteScreen
│   ├── → SyllabusScreen
│   │       └── → PdfViewerScreen
│   ├── → NotificationsScreen
│   ├── → AllServicesScreen
│   │       ├── → AcademicCalendarScreen
│   │       ├── → DigitalIdScreen
│   │       ├── → ResultScreen
│   │       ├── → FormsScreen
│   │       ├── → QuickWebsiteScreen
│   │       ├── → QuickSupportScreen
│   │       ├── → SyllabusScreen
│   │       └── → NotificationsScreen
│   ├── → AcademicCalendarScreen
│   ├── → QuickSupportScreen (AI Chat)
│   └── → AppGuideScreen
│
├── Tab 1: ResultScreen
│   └── → ResultDisplayScreen
│           └── → Print PDF (PdfGenerator)
│
├── Tab 2: FormsScreen
│   └── → FormFillScreen
│       └── → PaymentScreen
│           └── → PaymentWebViewScreen
│
├── Tab 3: NotificationsScreen
│
├── Tab 4: SettingsScreen
│   ├── → ProfileScreen
│   ├── → ChangePasswordScreen
│   ├── → TermsConditionsScreen
│   ├── → PrivacyPolicyScreen
│   ├── → HelpFaqScreen
│   └── → ContactAboutScreen
│
└── LoginScreen
    └── → ForgotPasswordScreen
            └── → OtpVerificationScreen
                    └── → ResetPasswordScreen
```

### Screen Descriptions

| Screen | Purpose |
|--------|---------|
| `SplashScreen` | 3-sec animated splash, checks auth state |
| `LoginScreen` | Login/Register tabs, biometric button |
| `HomeScreen` | Main shell with IndexedStack + floating dock |
| `DashboardScreen` | Hero banner, quick services, notices, Nepali date |
| `ResultScreen` | Exam picker, symbol/DOB form, auto-detect |
| `ResultDisplayScreen` | Official grade sheet table with print |
| `FormsScreen` | Open/Closed exam form tabs with status badges |
| `FormFillScreen` | Subject checkboxes, theory/practical selection |
| `PaymentScreen` | Fee breakdown, gateway selection (4 gateways) |
| `PaymentWebViewScreen` | WebView for payment processing |
| `NotificationsScreen` | Scraped notices from fwuexam.edu.np |
| `ProfileScreen` | Full profile display, photo/signature upload |
| `SettingsScreen` | Account, notifications, general, support sections |
| `SyllabusScreen` | Tabbed syllabus browser with search |
| `PdfViewerScreen` | PDF.js/Office Online document viewer |
| `NoInternetScreen` | Offline fallback with retry |
| `AppGuideScreen` | Step-by-step feature documentation |
| `DigitalIdScreen` | Beautiful student ID card |
| `AcademicCalendarScreen` | BS calendar with event markers |
| `AllServicesScreen` | Grid of 13 services with search |
| `QuickSupportScreen` | AI chatbot (Gemini/Groq) |
| `QuickWebsiteScreen` | In-app WebView browser |
| `QuickNoticesScreen` | Latest 4 notices with AI summary |
| `ForgotPasswordScreen` | Email OTP initiation |
| `OtpVerificationScreen` | 6-digit OTP entry |
| `ResetPasswordScreen` | New password form |
| `ChangePasswordScreen` | Old + new password change |
| `ContactAboutScreen` | University info + dev team |
| `HelpFaqScreen` | Expandable FAQ tiles |
| `PrivacyPolicyScreen` | Privacy policy text |
| `TermsConditionsScreen` | Terms text |

---

## 9. Components & Widgets

### FloatingDock (components/floating_dock.dart)

Custom glassmorphism bottom navigation bar with 5 tabs.

```
┌─────────────────────────────────────────────────────┐
│ ╭───────────────────────────────────────────────╮   │
│ │  🏠    📊    📝    🔔    ⚙️                    │   │
│ │ Home  Result Forms Notice Settings            │   │
│ ╰───────────────────────────────────────────────╯   │
└─────────────────────────────────────────────────────┘
Features:
- BackdropFilter blur (glassmorphism)
- HapticFeedback on tap
- Active tab: red accent + expanded label
- Animated icon transitions
```

### FloatingAiBubble (components/floating_ai_bubble.dart)

Draggable floating action button for AI access.

```
Features:
- Positioned bottom-right by default
- Draggable to any screen position
- Pulsing scale animation (1.0 → 1.08)
- "Ask Question" slide-in label
- Indigo gradient (#6366F1)
- Navigates to QuickSupportScreen
```

### ConnectivityWrapper (widgets/connectivity_wrapper.dart)

Global network monitor wrapping the entire app.

```
ConnectivityWrapper
├── Online → child widget (normal app)
└── Offline → NoInternetScreen (retry button)

Uses: connectivity_plus package
Listens: Connectivity().onConnectivityChanged
```

### LatestUpdateCard (widgets/latest_update_card.dart)

Notice card with HTML scraping and local caching.

```
Features:
- Scrapes https://fwuexam.edu.np/notice.html
- Caches to SharedPreferences
- Shimmer loading animation
- Expandable list with "Show All" toggle
- "View" button opens URL externally
```

---

## 10. API & Backend Integration

### Data Fetching Strategy

Since FWU has **no public REST API**, the app uses an innovative HTML scraping approach:

```
┌──────────┐         ┌──────────────────┐         ┌──────────────┐
│  App     │ ──1──▶  │ POST /Login      │ ──2──▶  │ Session      │
│          │         │ (form-encoded)   │         │ Cookie       │
│          │ ◀──3──  │                  │ ◀────── │ (.ASPXAUTH)  │
│          │         └──────────────────┘         └──────────────┘
│          │
│          │ ──4──▶  GET /StudentPortal/Dashboard (with cookie)
│          │ ◀──5──  HTML containing: var data = {JSON...};
│          │
│          │ ──6──▶  Extract JSON via balanced-brace parsing
│          │ ◀──7──  StudentInfo model populated
└──────────┘
```

### API Endpoints

#### Authentication

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `https://exam.fwu.edu.np/Login` | Login with credentials |
| POST | `https://exam.fwu.edu.np/ChangePassword/Index` | Change password |

#### Student Data

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `https://exam.fwu.edu.np/StudentPortal/Dashboard` | Profile + schedules |
| GET | `https://exam.fwu.edu.np/studentportal/dashboard/GetFile/{id}` | Photo/signature |
| POST | `https://exam.fwu.edu.np/FileUpload/Upload/` | Upload image |
| POST | `https://exam.fwu.edu.np/studentportal/dashboard/UpdatePhoto/` | Update photo |
| POST | `https://exam.fwu.edu.np/studentportal/dashboard/UpdateSign/` | Update signature |

#### Exam Forms

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `https://exam.fwu.edu.np/StudentPortal/Application/Initialize` | Init form |
| GET | `https://exam.fwu.edu.np/StudentPortal/Application/Index` | Load form |
| POST | `https://exam.fwu.edu.np/StudentPortal/Application/Index` | Submit form |
| GET | `https://exam.fwu.edu.np/registration/default/downloadadmitcardbystudent` | Admit card |

#### Payments

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `https://exam.fwu.edu.np/studentportal/application/Esewa` | eSewa payment |
| POST | `https://exam.fwu.edu.np/studentportal/application/Khalti` | Khalti payment |
| POST | `https://exam.fwu.edu.np/studentportal/application/ConnectIps` | ConnectIPS |
| POST | `https://exam.fwu.edu.np/studentportal/application/HBL` | HBL payment |

#### Results

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `https://exam.fwu.edu.np/Result` | Published exams list |
| POST | `https://exam.fwu.edu.np/Result/Index` | Check result |

#### Custom Backend

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `https://fwuapi.hamrotayari.com/api.php` | Sync student contact |
| POST | `https://fwuapi.hamrotayari.com/get_contact.php` | Get linked email |

#### Notices (HTML Scraping)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `https://fwuexam.edu.np/notice.html` | Exam notices |
| GET | `https://www.fwu.edu.np/notice.html` | University notices |

---

## 11. Payment Gateway Integration

### Supported Gateways

```
┌─────────────────────────────────────────────────────────────┐
│                    Payment Flow                               │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐      │
│  │ Payment  │───▶│ Gateway  │───▶│  WebView Screen  │      │
│  │  Screen  │    │ Selection│    │  (Auto-submit    │      │
│  │          │    │          │    │   HTML form)     │      │
│  └──────────┘    └──────────┘    └────────┬─────────┘      │
│                                           │                  │
│                    ┌──────────────────────┼──────────┐       │
│                    │                      │          │       │
│                    ▼                      ▼          ▼       │
│           ┌──────────────┐      ┌─────────┐  ┌─────────┐   │
│           │   Success    │      │ Failure │  │ Cancel  │   │
│           │   Redirect   │      │ Detect  │  │ Detect  │   │
│           └──────┬───────┘      └────┬────┘  └────┬────┘   │
│                  │                    │            │         │
│                  ▼                    ▼            ▼         │
│           ┌──────────────┐    ┌──────────┐  ┌─────────┐   │
│           │ onSuccess()  │    │ onFail() │  │ Pop()   │   │
│           │ → FormFill   │    │ → Retry  │  │ → Back  │   │
│           └──────────────┘    └──────────┘  └─────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Gateway Details

| Gateway | Key | Color | Initiation |
|---------|-----|-------|-----------|
| eSewa | `Esewa` | Green (#60BB46) | Form POST to eSewa |
| Khalti | `Khalti` | Purple (#5C2D91) | Form POST to Khalti |
| ConnectIPS | `ConnectIps` | Blue (#1A3F7A) | Form POST to CIPS |
| HBL | `HBL` | Red (#D71920) | Form POST to HBL |

### Payment Detection

The WebView monitors URL changes to detect payment outcomes:
- **Success patterns:** URLs containing `verify`, `success`, `complete`
- **Failure patterns:** URLs containing `fail`, `error`, `cancel`
- **File downloads:** Detected and saved to device

---

## 12. AI Integration

### Dual-Provider Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI Chat Flow                                  │
│                                                                  │
│  User Message                                                    │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────────────────────────────┐                           │
│  │     Build Context                 │                           │
│  │  • Student name, faculty          │                           │
│  │  • Registration number            │                           │
│  │  • Admit card info (if any)       │                           │
│  │  • Published results list         │                           │
│  │  • Current notices                │                           │
│  └──────────────┬───────────────────┘                           │
│                 │                                                 │
│                 ▼                                                 │
│  ┌──────────────────────────────────┐                           │
│  │       GeminiService              │                           │
│  │  Model: gemini-3.1-flash-lite    │                           │
│  │  Retry: 2x with backoff          │                           │
│  └──────────────┬───────────────────┘                           │
│                 │                                                 │
│        ┌────────┼────────┐                                       │
│        │ Success         │ All models fail                       │
│        ▼                 ▼                                       │
│  ┌──────────┐    ┌──────────────────────────┐                   │
│  │ Response │    │      GroqService          │                   │
│  │ Display  │    │  Model: llama-3.3-70b     │                   │
│  └──────────┘    └──────────────┬────────────┘                   │
│                                 │                                 │
│                                 ▼                                 │
│                          ┌──────────┐                            │
│                          │ Response │                            │
│                          │ Display  │                            │
│                          └──────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### AI Features

1. **Context-Aware Responses:** AI knows student's name, faculty, registration number, admit cards, and published results
2. **Navigation Buttons:** AI can generate clickable `[[Action: Title|Route]]` buttons
3. **In-Chat Result Checking:** `[[Action: Check Results|FetchResult:SYMBOL|DOB|EXAM_ID]]`
4. **Notice Summarization:** Can summarize scraped notice content
5. **Follow-up Prompts:** Suggests relevant next questions
6. **Typing Animation:** Word-by-word response display

### System Prompt Scope

The AI is **strictly scoped** to FWU-related queries only:
- University information and policies
- Exam schedules and registration
- Result interpretation
- Navigation help within the app
- Notice summarization

---

## 13. Security & Authentication

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   Authentication Flow                             │
│                                                                  │
│  ┌───────────┐    POST credentials    ┌────────────────┐       │
│  │   User    │ ─────────────────────▶  │ exam.fwu.edu.np│       │
│  │   Input   │                         │    /Login       │       │
│  └───────────┘                         └───────┬────────┘       │
│                                                 │                │
│                              ┌──────────────────┼──────┐        │
│                              │ Success          │Fail  │        │
│                              ▼                  ▼      │        │
│                    ┌──────────────────┐   ┌─────────┐ │        │
│                    │ Extract Cookies  │   │ Error   │ │        │
│                    │ (.ASPXAUTH etc.) │   │ Message │ │        │
│                    └────────┬─────────┘   └─────────┘ │        │
│                             │                         │         │
│                             ▼                         │         │
│                    ┌──────────────────┐               │         │
│                    │ Store in Secure  │               │         │
│                    │ Storage (AES)    │               │         │
│                    └────────┬─────────┘               │         │
│                             │                         │         │
│                             ▼                         │         │
│                    ┌──────────────────┐               │         │
│                    │ Fetch Profile    │               │         │
│                    │ (Dashboard HTML) │               │         │
│                    └────────┬─────────┘               │         │
│                             │                         │         │
│                             ▼                         │         │
│                    ┌──────────────────┐               │         │
│                    │ Navigate to      │               │         │
│                    │ HomeScreen       │               │         │
│                    └──────────────────┘               │         │
└─────────────────────────────────────────────────────────────────┘
```

### Security Features

| Feature | Implementation |
|---------|---------------|
| **Credential Storage** | `flutter_secure_storage` (AES encrypted) |
| **Session Management** | HTTP-only cookies, stored securely |
| **Biometric Auth** | `local_auth` (fingerprint/face) |
| **Password Detection** | Detects DOB-format passwords, prompts change |
| **SSL Handling** | Custom `badCertificateCallback` for FWU cert |
| **OTP Verification** | 6-digit email OTP for password reset |
| **Auto-logout** | Clears secure storage on logout |

### Biometric Login Flow

```
User taps fingerprint icon
        │
        ▼
local_auth.authenticate()
        │
   ┌────┼────┐
   │Success  │Fail
   ▼         ▼
Read saved    Show error
credentials
from Secure
Storage
        │
        ▼
Auto-login with
saved username/
password
```

---

## 14. Architecture Diagrams

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FWU Mobile App                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Flutter Framework                          │    │
│  │                                                              │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │    │
│  │  │   UI     │  │  State   │  │ Services │  │  Utils   │   │    │
│  │  │ (Screens │  │(Providers│  │(AI, SMTP)│  │(PDF Gen) │   │    │
│  │  │ Widgets) │  │ Models)  │  │          │  │          │   │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │    │
│  │       │              │              │              │          │    │
│  └───────┼──────────────┼──────────────┼──────────────┼──────────┘    │
│          │              │              │              │               │
└──────────┼──────────────┼──────────────┼──────────────┼───────────────┘
           │              │              │              │
           ▼              ▼              ▼              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       External Services                               │
│                                                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────┐ ┌─────────────┐  │
│  │FWU EMIS      │ │Google Gemini │ │  Groq API  │ │Gmail SMTP   │  │
│  │exam.fwu.edu  │ │    API       │ │            │ │             │  │
│  │.np           │ │              │ │            │ │             │  │
│  └──────────────┘ └──────────────┘ └────────────┘ └─────────────┘  │
│                                                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────┐ ┌─────────────┐  │
│  │Custom API    │ │eSewa Gateway │ │Khalti      │ │ConnectIPS/  │  │
│  │hamrotayari   │ │              │ │Gateway     │ │HBL Gateway  │  │
│  │.com          │ │              │ │            │ │             │  │
│  └──────────────┘ └──────────────┘ └────────────┘ └─────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Data Flow                                  │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │                    UI Layer                              │    │
│   │                                                          │    │
│   │   Consumer<AuthProvider>     Consumer<ResultProvider>     │    │
│   │   Consumer<FormProvider>     context.read<...>()         │    │
│   └──────────────────────┬───────────────────────────────────┘    │
│                          │ notifyListeners()                      │
│                          ▼                                        │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │               Provider Layer (State)                     │    │
│   │                                                          │    │
│   │   AuthProvider ←──── StudentInfo                         │    │
│   │        │              sessionCookie                       │    │
│   │        │                                                 │    │
│   │   ResultProvider ←── ExamResult                          │    │
│   │        │              ExamSchedule[]                      │    │
│   │        │                                                 │    │
│   │   FormProvider ←──── ExamFormData                        │    │
│   │        │              ExamSchedule[]                      │    │
│   └────────┼─────────────────────────────────────────────────┘    │
│            │ HTTP requests                                        │
│            ▼                                                      │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │              Network Layer                               │    │
│   │                                                          │    │
│   │   HTTP Client ──── Session Cookies ──── SSL Bypass       │    │
│   │        │                                                 │    │
│   │        ├──── HTML Response ──── JSON Extraction           │    │
│   │        │     (balanced brace parser)                     │    │
│   │        │                                                 │    │
│   │        └──── Form Encoded POST                           │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │              Storage Layer                               │    │
│   │                                                          │    │
│   │   flutter_secure_storage ──── Credentials, Cookies       │    │
│   │   shared_preferences    ──── Cached Notices, Settings    │    │
│   └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### Component Dependency Graph

```
main.dart
├── constants.dart (AppColors, AppConfig)
├── providers/
│   ├── auth_provider.dart
│   │   └── models/student_model.dart
│   ├── result_provider.dart
│   │   └── models/result_model.dart
│   └── form_provider.dart
│       └── models/form_model.dart
├── screens/splash_screen.dart
│   ├── screens/login_screen.dart
│   │   └── screens/forgot_password/...
│   └── screens/home_screen.dart
│       ├── screens/dashboard_screen.dart
│       │   └── screens/quick_actions/...
│       ├── screens/result_screen.dart
│       │   └── screens/result_display_screen.dart
│       ├── screens/forms_screen.dart
│       │   ├── screens/form_fill_screen.dart
│       │   └── screens/payment_screen.dart
│       │       └── screens/payment_webview_screen.dart
│       ├── screens/notifications_screen.dart
│       └── screens/settings_screen.dart
│           └── screens/setting_widgets/...
├── services/
│   ├── gemini_service.dart
│   ├── groq_service.dart
│   └── smtp_service.dart
├── widgets/
│   ├── connectivity_wrapper.dart
│   ├── latest_update_card.dart
│   ├── rate_us_card.dart
│   └── app_guide_section.dart
├── components/
│   ├── floating_dock.dart
│   └── floating_ai_bubble.dart
└── utils/
    └── pdf_generator.dart
```

---

## 15. Workflow Diagrams

### App Startup Workflow

```
┌─────────┐     ┌──────────┐     ┌──────────────┐     ┌────────────┐
│  Start  │────▶│  Load    │────▶│  Check Auth  │────▶│  Navigate  │
│         │     │  .env    │     │  (Secure     │     │            │
└─────────┘     │  file    │     │   Storage)   │     └─────┬──────┘
                └──────────┘     └──────────────┘           │
                                                    ┌───────┼───────┐
                                                    ▼               ▼
                                             ┌───────────┐  ┌───────────┐
                                             │LoginScreen│  │HomeScreen │
                                             └───────────┘  └───────────┘
```

### Login Workflow

```
┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌────────────┐
│  Enter   │───▶│   POST to    │───▶│  Extract    │───▶│  Fetch     │
│  Creds   │    │   /Login     │    │  Cookies    │    │  Profile   │
└──────────┘    └──────────────┘    └─────────────┘    └─────┬──────┘
                                                              │
                                                              ▼
┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌────────────┐
│  Home    │◀───│  Save to     │◀───│  Parse HTML │◀───│  GET       │
│  Screen  │    │  SecStorage  │    │  Extract    │    │ /Dashboard │
└──────────┘    └──────────────┘    │  JSON data  │    └────────────┘
                                    └─────────────┘
```

### Exam Form Submission Workflow

```
┌─────────┐   ┌──────────┐   ┌─────────────┐   ┌──────────────┐
│  View   │──▶│  Select  │──▶│  Initialize │──▶│    Load      │
│  Open   │   │  Exam    │   │  Form POST  │   │  Form GET    │
│  Forms  │   │  Schedule│   │             │   │              │
└─────────┘   └──────────┘   └─────────────┘   └──────┬───────┘
                                                       │
                              ┌─────────────────────────┤
                              │                         │
                              ▼                         ▼
                     ┌──────────────┐         ┌──────────────┐
                     │  Payment     │         │   Subject    │
                     │  Required    │         │   Selection  │
                     └──────┬───────┘         └──────┬───────┘
                            │                        │
                            ▼                        ▼
                     ┌──────────────┐         ┌──────────────┐
                     │  Select      │         │   Submit     │
                     │  Gateway     │         │   Form       │
                     └──────┬───────┘         └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  WebView     │
                     │  Payment     │
                     └──────┬───────┘
                            │
                     ┌──────┼──────┐
                     ▼      ▼      ▼
                  Success  Fail  Cancel
                     │      │      │
                     ▼      │      │
              ┌──────────┐  │      │
              │Back to   │◀─┘      │
              │Form Fill │◀────────┘
              └──────────┘
```

### Result Checking Workflow

```
┌─────────────┐    ┌─────────────┐    ┌──────────────┐
│  Select     │───▶│  Enter      │───▶│  POST to     │
│  Exam       │    │  Symbol No  │    │  /Result     │
│  Schedule   │    │  + DOB      │    │  /Index      │
└─────────────┘    └─────────────┘    └──────┬───────┘
                                              │
                                              ▼
┌─────────────┐    ┌─────────────┐    ┌──────────────┐
│  Print PDF  │◀───│  Display    │◀───│  Parse       │
│  (optional) │    │  Grade      │    │  ExamResult  │
│             │    │  Sheet      │    │  JSON        │
└─────────────┘    └─────────────┘    └──────────────┘

Auto-Detect Feature:
┌─────────────┐    ┌──────────────────┐    ┌──────────────┐
│  On Screen  │───▶│  Cross-reference │───▶│  Auto-fill   │
│  Load       │    │  Admit Cards     │    │  & Check     │
│             │    │  with Published  │    │  Result      │
└─────────────┘    │  Results         │    └──────────────┘
                   └──────────────────┘
```

### Password Reset Workflow

```
┌─────────────┐    ┌─────────────┐    ┌──────────────┐
│  Enter      │───▶│  Verify     │───▶│  Send OTP    │
│  Reg. No    │    │  Email      │    │  via SMTP    │
│  + Email    │    │  Match      │    │              │
└─────────────┘    └─────────────┘    └──────┬───────┘
                                              │
                                              ▼
┌─────────────┐    ┌─────────────┐    ┌──────────────┐
│  Password   │◀───│  Enter      │◀───│  6-Digit     │
│  Changed    │    │  New Pass   │    │  OTP Input   │
│  Success    │    │             │    │              │
└─────────────┘    └─────────────┘    └──────────────┘
```

### AI Chat Workflow

```
┌──────────┐    ┌──────────────────┐    ┌──────────────┐
│  User    │───▶│  Build Context   │───▶│  Gemini API  │
│  Message │    │  • Student info  │    │  (Primary)   │
│          │    │  • Admit cards   │    └──────┬───────┘
└──────────┘    │  • Results       │           │
                │  • Notices       │    ┌──────┼──────┐
                └──────────────────┘    │ OK   │ Fail │
                                        ▼      ▼      │
                                 ┌──────────┐  ┌──────┴────┐
                                 │ Display  │  │ Groq API  │
                                 │ Response │  │ (Fallback)│
                                 └──────────┘  └──────┬────┘
                                                      │
                                        ┌─────────────┼─────┐
                                        ▼                   ▼
                                 ┌──────────┐         ┌─────────┐
                                 │ Display  │         │  Error  │
                                 │ Response │         │ Message │
                                 └──────────┘         └─────────┘

Special AI Actions:
┌──────────────────────────────────────────────────────────┐
│  [[Action: Check Results|FetchResult:SYMB|DOB|EXAM_ID]]  │
│       │                                                   │
│       ▼                                                   │
│  ResultProvider.checkStudentResult()                      │
│       │                                                   │
│       ▼                                                   │
│  Render in-chat grade sheet card                         │
└──────────────────────────────────────────────────────────┘
```

### Connectivity Monitoring Workflow

```
                    App Running
                        │
                        ▼
            ┌───────────────────────┐
            │ ConnectivityWrapper   │
            │ (listens to changes) │
            └───────────┬───────────┘
                        │
            ┌───────────┼───────────┐
            │ Connected             │ Disconnected
            ▼                       ▼
     ┌──────────────┐       ┌──────────────┐
     │ Show Normal  │       │ Show         │
     │ App Content  │       │ NoInternet   │
     │              │       │ Screen       │
     └──────────────┘       └──────┬───────┘
                                   │
                                   ▼
                            ┌──────────────┐
                            │ Retry Button │──── Re-check
                            └──────────────┘     connectivity
```

---

## 16. Environment Configuration

### .env File Structure

```env
# Backend API
BASE_URL=http://10.0.2.2:3000

# AI Services
GEMINI_API_KEY=your_gemini_api_key_here
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile

# SMTP (Password Reset)
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Custom API
FWU_API_KEY=your_api_key
```

### Android Permissions

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

---

## 17. Dependencies

### Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core framework |
| `http` | ^1.6.0 | HTTP client |
| `shared_preferences` | ^2.5.5 | Local key-value storage |
| `google_fonts` | ^8.0.2 | Typography (Inter) |
| `font_awesome_flutter` | ^11.0.0 | Icon pack |
| `provider` | ^6.1.5+1 | State management |
| `flutter_secure_storage` | ^10.0.0 | Encrypted credential storage |
| `url_launcher` | ^6.3.1 | Open external URLs |
| `path_provider` | ^2.1.5 | File system paths |
| `open_filex` | ^4.6.0 | Open downloaded files |
| `flutter_inappwebview` | ^6.1.5 | Advanced WebView |
| `connectivity_plus` | ^7.1.0 | Network status monitoring |
| `local_auth` | ^3.0.1 | Biometric authentication |
| `html` | ^0.15.6 | HTML parsing |
| `webview_flutter` | ^4.13.1 | WebView (legacy) |
| `pdf` | ^3.12.0 | PDF generation |
| `printing` | ^5.14.3 | PDF printing/saving |
| `mailer` | ^7.1.0 | SMTP email sending |
| `flutter_dotenv` | ^6.0.0 | Environment variables |
| `image_picker` | ^1.2.1 | Camera/gallery image picking |
| `http_parser` | ^4.1.2 | HTTP multipart headers |
| `flutter_markdown` | ^0.7.7+1 | Markdown rendering (AI chat) |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Testing framework |
| `flutter_lints` | ^6.0.0 | Lint rules |
| `flutter_launcher_icons` | ^0.14.3 | App icon generation |
| `flutter_native_splash` | ^2.4.3 | Splash screen generation |

---

## 18. Build & Deployment

### Build Commands

```bash
# Get dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Run on device
flutter run
```

### App Configuration

| Setting | Value |
|---------|-------|
| **App Name** | FWU Mobile |
| **Package** | fwu_mobile |
| **Version** | 1.0.0+1 |
| **Min Android SDK** | 21 (Android 5.0) |
| **Dart SDK** | ^3.11.3 |
| **Splash Color** | #F1F5F9 |
| **Primary Color** | #00A65A (FWU Green) |

### Project Statistics

| Metric | Count |
|--------|-------|
| **Total Dart Files** | 50+ |
| **Screens** | 29 |
| **Providers** | 3 |
| **Models** | 3 (6 classes) |
| **Services** | 3 |
| **Widgets** | 4 |
| **Components** | 2 |
| **Utilities** | 1 |
| **External APIs** | 8+ endpoints |
| **Payment Gateways** | 4 |

---

## Summary

FWU Mobile is a feature-rich Flutter application that bridges the gap between Far Western University's legacy web portal and modern mobile experience. Through innovative HTML scraping, session-based authentication, AI-powered assistance, and seamless payment integration, it provides students with a comprehensive academic management tool.

The architecture prioritizes:
- **Reliability:** Dual AI provider fallback, offline caching, connectivity monitoring
- **Security:** Encrypted storage, biometric auth, session management
- **User Experience:** Material Design 3, animations, Nepali calendar integration
- **Maintainability:** Clean Provider pattern, separated concerns, modular screens

---

*Documentation generated for FWU Mobile v1.0.0*
*Far Western University, Nepal*
