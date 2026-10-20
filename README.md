# 🏍️ Nexora Rider - Courier & Delivery Partner Mobile App

A high-performance courier and logistics mobile application built with **Flutter** and **Material 3**, purpose-built as the companion delivery partner app for the **Nexora E-Commerce Ecosystem**.

---

## 🌟 Key Features & Highlights

### ⚡ 1. Duty & Shift Operations
- **Online / Offline Duty Toggle**: One-tap shift activation with animated status indicators and live shift duration tracking.
- **Vehicle & Hub Identity**: Displays assigned vehicle specifications (*Yamaha NMAX 155*), plate number (*NCR 8821-X*), and primary hub (*Makati / BGC Central Hub #4*).
- **Surge Hotspot Alerts**: Real-time high-density dispatch notifications with dynamic trip bonuses (*e.g., +₱30/trip surge*).

### 📦 2. Dispatch Pool & Order Acceptance
- **Dispatch Cards**: Real-time incoming requests displaying transparent earnings (*delivery fee + tip*), distance, estimated travel time, and item count.
- **Interactive Simulation**: Built-in `Simulate Ping` action to easily trigger realistic incoming dispatch requests on demand.
- **Accept / Decline Actions**: Rapid decision flow with instant route assignment.

### 🗺️ 3. Active Delivery & Navigation Workflow
- **5-Stage Live Stepper**:
  1. *Headed to Store*
  2. *At Store / Picking Up*
  3. *In Transit to Customer*
  4. *Arrived at Drop-off*
  5. *Delivered & Complete*
- **Turn-by-Turn GPS Simulation**: In-app turn prompts with quick launch integration for Google Maps.
- **Package Item Checklist**: Interactive item verification list to ensure all customer items are accounted for before leaving the merchant.
- **Customer & Store Direct Contact**: One-tap phone calling and integrated in-app messaging.

### 💬 4. In-App Customer Chat
- **Real-Time Communication**: Threaded chat with the recipient (*e.g. Alex Rivera*).
- **Quick Reply Chips**: Pre-composed quick messages (*"I'm heading to the store"*, *"Waiting for items"*, *"Arrived at your lobby"*, *"Please prepare exact COD cash"*).

### 📸 5. Proof of Delivery (POD) & COD Handover
- **Doorstep Photo Verification**: Capture delivery photos at the customer's doorstep or reception.
- **Cash on Delivery (COD) Collection**: Interactive confirmation of cash collection before completing orders.
- **Recipient Handover Notes**: Digital log of handover details (*e.g., "Left with tower reception"*).

### 💰 6. Earnings & Instant Wallet Cashout
- **Daily & Weekly Analytics**: 7-day visual performance bar chart with past week comparisons.
- **Instant Cashout Modal**: Withdraw wallet funds directly to:
  - **GCash**
  - **Maya**
  - **BDO Unibank**
  - **BPI Bank**
- **Transaction Ledger**: Complete history of trip payouts, customer tips, surge incentives, and withdrawals.

### 🛡️ 7. Rider Profile & Safety First
- **Compliance Badges**: LTO Professional Driver License, OR/CR Registration, and NBI Clearance verification statuses.
- **24/7 Roadside Emergency SOS**: Dedicated emergency assistance dialog for roadside incidents or rider support.

---

## 🏗️ Project Architecture

```
nexora_rider_app/lib/
├── core/
│   ├── models/
│   │   ├── chat_message.dart         # Chat message models
│   │   ├── delivery_order.dart       # Order lifecycle, items, and address models
│   │   ├── earning_record.dart       # Transaction and daily earnings models
│   │   └── rider_profile.dart        # Rider profile, vehicle, and metrics models
│   ├── services/
│   │   ├── chat_service.dart         # Customer-rider messaging service
│   │   ├── delivery_service.dart     # Order dispatches and active lifecycle state
│   │   ├── earnings_service.dart     # Wallet, payouts, and cash-out processing
│   │   └── rider_service.dart        # Shift toggle and profile state manager
│   ├── theme/
│   │   └── rider_theme.dart          # Nexora brand tokens and Material 3 theme
│   └── widgets/
│       ├── nexora_button.dart        # Branded primary buttons
│       └── status_badge.dart         # Status chips and pill badges
├── features/
│   ├── chat/
│   │   └── presentation/
│   │       └── rider_chat_screen.dart
│   ├── delivery/
│   │   └── presentation/
│   │       ├── active_delivery_screen.dart
│   │       ├── delivery_history_screen.dart
│   │       ├── proof_of_delivery_sheet.dart
│   │       └── widgets/
│   │           └── route_progress_widget.dart
│   ├── earnings/
│   │   └── presentation/
│   │       ├── earnings_screen.dart
│   │       └── widgets/
│   │           ├── cash_out_bottom_sheet.dart
│   │           └── weekly_chart_widget.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── rider_home_screen.dart
│   │       └── widgets/
│   │           ├── available_order_card.dart
│   │           ├── earnings_summary_card.dart
│   │           ├── hotspots_banner.dart
│   │           └── online_status_card.dart
│   ├── profile/
│   │   └── presentation/
│   │       └── rider_profile_screen.dart
│   └── shell/
│       └── presentation/
│           └── rider_shell.dart       # Bottom navigation shell with badges
└── main.dart                          # App entrypoint
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Chrome / Edge (Web) or Android/iOS Device/Emulator or Windows Desktop

---

## 💻 How to Run the Project

### 1. Navigate to Project Directory
```bash
cd "c:\Users\SERIES\Desktop\E-commerce FLUTTER Project\nexora_rider_app"
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Launch Application

#### 🌐 Run on Web (Chrome)
```bash
flutter run -d chrome
```

#### 💻 Run on Windows Desktop
```bash
flutter run -d windows
```

#### 📱 Run on Android / iOS
```bash
flutter run
```

---

## 🧪 Testing & Code Quality

Run tests to ensure everything is functioning correctly:
```bash
flutter test
```

Run static code analysis:
```bash
flutter analyze
```

---

## 🎨 Color Palette & Design Tokens

| Token | Hex Code | Description |
|---|---|---|
| **Primary** | `#0066FF` | Nexora Electric Blue |
| **Dark Navy** | `#050B28` | Primary contrast and top headers |
| **Secondary** | `#00D2FF` | Cyan highlight |
| **Online Green** | `#10B981` | Duty active, success, earnings payouts |
| **Warning Orange** | `#F59E0B` | Cash on Delivery (COD), attention alerts |
| **Error / SOS Red** | `#EF4444` | Emergency SOS, declines, cash withdrawals |
| **Background** | `#F6F8FC` | Clean soft-slate surface |

---

## 🤝 Nexora Ecosystem Compatibility
- **Customer App**: `nexora_flutter_app`
- **Rider App**: `nexora_rider_app`
- Both apps share synchronized order models, status lifecycles, and branding tokens for a cohesive cross-platform experience.
