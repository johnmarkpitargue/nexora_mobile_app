# 🔐 Nexora Supabase Database & Google Login Setup Guide

This guide walks you through setting up the **Nexora Supabase Database** and configuring **Google OAuth 2.0 Login** for both the Customer and Rider applications.

---

## 🗄️ Step 1: Run the Database Migration in Supabase

1. Open your browser and go to your **[Supabase Project Dashboard](https://supabase.com/dashboard/project/gxrgpfxrxzfykdnwvakp)**.
2. In the left navigation menu, click **SQL Editor**.
3. Click **New Query**.
4. Open [`nexora_flutter_app/supabase/schema.sql`](file:///C:/Users/SERIES/Desktop/E-commerce%20FLUTTER%20Project/nexora_flutter_app/supabase/schema.sql), copy the entire SQL script, and paste it into the editor.
5. Click **Run** (or press `Ctrl + Enter`).
6. Verify in **Table Editor** that the following tables are created:
   - ✅ `profiles` (integrated with `auth.users` via trigger `on_auth_user_created`)
   - ✅ `addresses` (customer shipping addresses)
   - ✅ `orders` (real-time order sync between customer and rider)
   - ✅ `rider_profiles` (fleet couriers, rating, vehicle, shift status)
   - ✅ `rider_reviews` (customer reviews & star ratings for riders)
   - ✅ `chat_messages` (live in-app customer & courier messaging)

---

## 🌐 Step 2: Configure Google Cloud Console (OAuth Credentials)

1. Go to the **[Google Cloud Console](https://console.cloud.google.com/)**.
2. Select or create your project (e.g. `Nexora App`).
3. Navigate to **APIs & Services** $\rightarrow$ **OAuth consent screen**:
   - User Type: **External** $\rightarrow$ Click **Create**.
   - App Name: `Nexora`
   - User support email: Select your email.
   - Developer contact email: Enter your email.
   - Scopes: Ensure `.../auth/userinfo.email` and `.../auth/userinfo.profile` are added.
   - Save and continue.
4. Navigate to **APIs & Services** $\rightarrow$ **Credentials**:
   - Click **+ CREATE CREDENTIALS** $\rightarrow$ **OAuth client ID**.
   - Application type: **Web application**.
   - Name: `Nexora Web / Supabase Auth`.
   - **Authorized redirect URIs**:
     ```
     https://gxrgpfxrxzfykdnwvakp.supabase.co/auth/v1/callback
     ```
   - Click **Create**.
   - Copy the **Client ID** and **Client Secret**.

---

## 🔑 Step 3: Enable Google Provider in Supabase

1. Back in the **Supabase Dashboard**, navigate to **Authentication** $\rightarrow$ **Providers**.
2. Locate **Google** in the list and toggle it to **Enabled**.
3. Paste the **Client ID** and **Client Secret** obtained from Google Cloud Console.
4. Click **Save**.

---

## 📱 Step 4: Configure App Deep Linking (for Mobile Redirects)

When Google Sign-In completes in the browser, it needs to redirect back into your Flutter application.

### Android Setup (`android/app/src/main/AndroidManifest.xml`):
Add the intent filter inside `<activity android:name=".MainActivity" ...>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.nexora"
        android:host="login-callback" />
</intent-filter>
```

### iOS Setup (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.nexora</string>
        </array>
    </dict>
</array>
```

---

## 🚀 Step 5: Ready-to-Use Flutter Auth Integration

A dedicated service [`SupabaseAuthService`](file:///C:/Users/SERIES/Desktop/E-commerce%20FLUTTER%20Project/nexora_flutter_app/lib/core/services/supabase_auth_service.dart) provides:
- **`signInWithGoogle()`**: Launches Google OAuth with deep linking redirect.
- **`signInWithEmail(email, password)`**: Signs in user and fetches their profile.
- **`signUpWithEmail(email, password, metadata)`**: Creates an account; automatically provisions `profiles` row via the database trigger.
- **`signOut()`**: Ends session and clears active profile.

