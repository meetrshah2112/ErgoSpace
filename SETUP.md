# ErgoSpace: Detailed Setup Guide

This guide takes you from a fresh clone to the app running on an Android emulator. Commands are shown for Windows PowerShell; they also work on macOS/Linux unless noted.

**Contents**
1. [Prerequisites](#1-prerequisites)
2. [Clone the repository](#2-clone-the-repository)
3. [Generate your secrets](#3-generate-your-secrets)
4. [Get Razorpay test keys](#4-get-razorpay-test-keys)
5. [Configure the backend](#5-configure-the-backend-env)
6. [Start the backend and database with Docker](#6-start-the-backend-and-database-with-docker)
7. [Set up the Flutter frontend](#7-set-up-the-flutter-frontend)
8. [Run the app](#8-run-the-app)
9. [Test a payment](#9-test-a-payment)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

| Tool | Why | Check |
| --- | --- | --- |
| Git | clone the repo | `git --version` |
| Docker Desktop (with Compose) | runs PostGIS and the backend | `docker compose version` |
| Python 3 | only to generate secrets (optional) | `python --version` |
| Flutter SDK | builds the app | `flutter doctor` |
| Android Studio + an emulator (or a phone with USB debugging) | runs the app | `flutter devices` |
| Razorpay account | payments (test mode is free) | see step 4 |

Run `flutter doctor` and fix anything it marks with a red cross before continuing.

## 2. Clone the repository

```powershell
git clone https://github.com/<your-username>/ErgoSpace.git
cd ErgoSpace
```

## 3. Generate your secrets

You need two values: a **Django secret key** and a **database password**. Python's built-in `secrets` module generates both and needs no extra install.

**Django `SECRET_KEY`**
```powershell
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

**Database password**
```powershell
python -c "import secrets; print(secrets.token_urlsafe(24))"
```

Copy each output somewhere safe for step 5. No Python? Use any password manager's generator (about 50 random characters for the secret key, 24 for the password).

> Never reuse these values from a tutorial or commit them to GitHub.

## 4. Get Razorpay test keys

1. Go to [razorpay.com](https://razorpay.com) and sign up or log in to the **Dashboard**.
2. Switch the dashboard to **Test Mode** (toggle at the top). Test mode needs no business verification and moves no real money.
3. Open **Account & Settings** and then **API Keys** (menu names can vary slightly between dashboard versions).
4. Click **Generate Test Key**.
5. Copy both values now:
   - **Key ID** (starts with `rzp_test_`). This goes in the backend `.env` and in the Flutter run command.
   - **Key Secret**. This is shown only once. It goes **only** in the backend `.env`.

If you lose the secret, regenerate the key and update your `.env`.

## 5. Configure the backend (.env)

```powershell
copy backend\.env.example backend\.env        # macOS/Linux: cp backend/.env.example backend/.env
```

Open `backend/.env` and fill in:

| Variable | Value |
| --- | --- |
| `SECRET_KEY` | the Django secret key from step 3 |
| `DEBUG` | `True` for local development |
| `ALLOWED_HOSTS` | `localhost,127.0.0.1,10.0.2.2` (add your computer's LAN IP if you test on a real phone) |
| `DB_NAME` / `DB_USER` | keep the defaults |
| `DB_PASSWORD` | the database password from step 3 |
| `DB_HOST` | keep `localhost` (Docker overrides it) |
| `RAZORPAY_KEY_ID` | Key ID from step 4 |
| `RAZORPAY_KEY_SECRET` | Key Secret from step 4 |
| `CORS_ALLOWED_ORIGINS`, `CSRF_TRUSTED_ORIGINS` | keep the defaults for local use |
| `COOKIE_SECURE` / `COOKIE_SAMESITE` | `False` / `Lax` for local HTTP |

## 6. Start the backend and database with Docker

From the repository root (where `docker-compose.yml` is):

```powershell
docker compose --env-file backend/.env up --build
```

What happens automatically:
1. A PostGIS database container starts, using `DB_NAME`, `DB_USER` and `DB_PASSWORD`.
2. The backend image is built with the GIS libraries (GDAL, GEOS) installed.
3. Once the database is healthy, the backend runs `python manage.py migrate`. This creates all tables and adds the default amenities.
4. The API starts at **http://localhost:8000**.

Wait until the log shows `Starting development server at http://0.0.0.0:8000/`.

Optional but recommended:

```powershell
# In a second terminal, from the repository root
docker compose exec backend python manage.py createsuperuser
```
Then open http://localhost:8000/admin to manage data.

Default images (optional): if you want default workspace images, place `logo.jpg` and `background.jpg` in `backend/media/`.

Useful commands:
```powershell
docker compose down            # stop everything (data is kept)
docker compose down -v         # stop and DELETE the database volume
docker compose logs -f backend # follow backend logs
```

## 7. Set up the Flutter frontend

```powershell
cd frontend
```

**7.1 Generate the Android platform folder**
```powershell
flutter create --org com.ergospace --platforms android .
```
Your `lib/`, `test/` and `pubspec.yaml` should stay unchanged; check with `git status` and restore them with `git checkout` if they were overwritten.

**7.2 Android configuration**

In `android/app/build.gradle` (or `build.gradle.kts`) set the minimum SDK:
```
minSdk = 23
```

In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>
</queries>
```
and on the `<application>` tag add (local HTTP development only; remove for production):
```xml
android:usesCleartextTraffic="true"
```

**7.3 Upgrade the location libraries (fixes the common build error)**

The location plugins (`geolocator`, `geocoding`) and their Android sub-packages sometimes fail to build with a newer Flutter/Android toolchain. Upgrading them fixes it:

```powershell
flutter pub upgrade geolocator geocoding url_launcher
```
If the error persists, upgrade every dependency to its latest allowed version:
```powershell
flutter pub upgrade --major-versions
```

**7.4 Clean and fetch packages**
```powershell
flutter clean
flutter pub get
```

## 8. Run the app

Start an emulator from Android Studio (Device Manager), or connect a phone. Check it is detected:
```powershell
flutter devices
```

**Android emulator** (it reaches your computer at `10.0.2.2`, which is the app's default):
```powershell
flutter run --dart-define=RAZORPAY_KEY=rzp_test_xxxxxxxxxxxx
```

**Physical phone** (same Wi-Fi as your computer):
1. Find your computer's IP (`ipconfig` on Windows, for example `192.168.1.10`).
2. Add it to `ALLOWED_HOSTS` in `backend/.env` and restart Docker.
3. Run:
```powershell
flutter run --device-id <your-device-id> `
  --dart-define=API_BASE_URL=http://192.168.1.10:8000 `
  --dart-define=RAZORPAY_KEY=rzp_test_xxxxxxxxxxxx
```

`RAZORPAY_KEY` must be the same **Key ID** as `RAZORPAY_KEY_ID` in `backend/.env`. Never pass the secret to Flutter.

## 9. Test a payment

1. Register one account as a **provider**, create a workspace (use *Use my current location*, add amenities and seat photos).
2. Register another account as a **customer**, open the workspace, choose a seat, pick hourly/daily/monthly, check availability and reserve.
3. Pay in Razorpay's checkout using **test-mode** details from Razorpay's documentation (their test card number works with any future expiry and any CVV). No real money is charged in test mode.

## 10. Troubleshooting

| Problem | Fix |
| --- | --- |
| `Invalid HTTP_HOST header` / 400 | Add the host or IP the app uses to `ALLOWED_HOSTS`, restart Docker |
| App cannot reach the backend | Check the backend is running, correct `API_BASE_URL`, same Wi-Fi, firewall allows port 8000 |
| Docker: `DB_PASSWORD` not set | Run with `--env-file backend/.env` and fill `DB_PASSWORD` |
| Database password change has no effect | The old volume still exists: `docker compose down -v`, then start again |
| Build error from a location plugin | Step 7.3, then `flutter clean` and `flutter pub get` |
| Razorpay checkout does not open | Run with `--dart-define=RAZORPAY_KEY=...` |
| Payment succeeds but booking stays pending | The Key ID in the app and the ID/secret in `.env` are from different Razorpay keys |
| Location button does nothing | Allow location permission on the device and keep GPS on |
| Missing default workspace images | Put `logo.jpg` and `background.jpg` in `backend/media/` |
