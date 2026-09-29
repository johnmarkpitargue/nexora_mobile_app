# 🛍️ Nexora Mobile - Flutter E-Commerce Application

An e-commerce Flutter mobile application built with **Material 3 guidelines**, responsive layouts, and modern architecture inspired by the **Stitch Design System (*Nexora Lumina*)**.

---

## 🌟 Features & Highlights

- **Stitch M3 Design System**: Custom theme with electric indigo (`#5538EE`), cyan, rose accents, and surface contrast.
- **Glassmorphic App Header & Floating Dock**: Translucent blurred app bar and floating pill navigation dock (`ImageFilter.blur`).
- **Live Active Order Tracker**: Order progress card featuring delivery ETA, 3-stage stepper (*Packed → Out for Delivery → Delivered*), and stop tracking.
- **Responsive Layout**: Adapts dynamically across mobile devices, foldables, and tablets using `LayoutBuilder`.
- **Search & Trend Discovery Bar**: Elevated search input with voice search, QR scanner controls, and trend carousel chips.
- **Product & Category Showcase**: Responsive grid cards with rating stars, wishlist toggles, discount badges, and quick-add actions.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version `^3.13.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Chrome / Edge (for Web development) or an Android/iOS Emulator / Physical Device.

---

## 💻 How to Run the Project

### 1. Navigate to Project Directory

Open your terminal or PowerShell and navigate to the project directory:

```bash
cd "c:\Users\SERIES\Desktop\E-commerce FLUTTER Project\nexora_flutter_app"
```

### 2. Install Dependencies

Fetch all required package dependencies:

```bash
flutter pub get
```

### 3. Launch the Application

Select your target platform and run the corresponding command:

#### 🌐 Run on Web (Chrome)
```bash
flutter run -d chrome
```

#### 💻 Run on Windows Desktop
```bash
flutter run -d windows
```

#### 📱 Run on Connected Mobile Device / Emulator
List available connected devices:
```bash
flutter devices
```
Run on your preferred device ID or default emulator:
```bash
flutter run
```

---

## ⚡ Development & Testing Commands

### Hot Reload & Hot Restart
While `flutter run` is active in your terminal:
- Press **`r`** for **Hot Reload** (instant stateful UI update)
- Press **`R`** for **Hot Restart** (re-initializes application state)
- Press **`q`** to quit the application

### Run Static Analysis
Ensure code quality and verify zero lint errors:
```bash
flutter analyze
```

### Run Unit & Widget Tests
Execute all automated widget tests:
```bash
flutter test
```

---

## 📂 Project Architecture

This application follows a clean **Feature-First Architecture**:

```text
lib/
├── main.dart                          # Application entry point & theme initialization
├── core/
│   ├── theme/
│   │   └── nexora_theme.dart          # Stitch Material 3 design tokens & theme setup
│   └── widgets/                       # App-wide shared reusable widgets
└── features/
    ├── auth/                          # Authentication feature (Login / Register)
    └── home/                          # Home feature
        └── presentation/
            ├── homepage.dart          # Main assembled home screen view
            └── widgets/               # Feature-specific home components
                ├── header_app_bar.dart
                ├── search_and_trend_section.dart
                ├── category_section.dart
                ├── active_order_tracker_card.dart
                ├── featured_products_section.dart
                ├── product_card.dart
                ├── weekly_perks_banner.dart
                └── floating_nav_dock.dart
```

---

## 📄 License

Distributed under private repository terms. All rights reserved.
