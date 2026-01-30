# Firebase Setup Guide

Follow these steps to configure your Firebase project for the E-Commerce App.

## 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project**.
3. Name it (e.g., `ECommerceApp`).
4. Disable Google Analytics (optional) and Create.

## 2. Add Android App
1. Click the **Android Icon** on the project overview page.
2. Enter Package Name: `com.csayse.flutter_admin_panel_development`
   *(This must match exactly)*.
3. Click **Register App**.
4. Click **Download google-services.json**.
5. Move this file to: `d:\Proje\flutter_admin_panel_development\flutter_admin_panel_development\android\app\`
   *(Ensure the filename is exactly `google-services.json`)*.

## 3. Configure Authentication
1. Go to **Build** > **Authentication**.
2. Click **Get Started**.
3. Select **Email/Password**.
4. Enable the first toggle (Email/Password).
5. Click **Save**.

## 4. Configure Firestore Database
1. Go to **Build** > **Firestore Database**.
2. Click **Create Database**.
3. Select a location `eur3`.
4. Select **Start in Test Mode**.
5. Click **Create**.

## 5. Configure Storage
1. Go to **Build** > **Storage**.
2. Click **Get Started**.
3. Select **Start in Test Mode**.
4. Click **Done**.


## 6. Run the App
After completing these steps:
1. Run `flutter clean` in the terminal.
2. Run `flutter run`.

If you encounter issues, please check the console output.
