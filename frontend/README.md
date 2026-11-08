# ErgoSpace (Flutter, Android)

## 1. Create the platform folders and drop this code in
```bash
flutter create --org com.ergospace --platforms android ergospace
cd ergospace
# copy lib/, test/, pubspec.yaml and README.md from this bundle over the generated ones
flutter pub get
```

## 2. Android configuration
`android/app/build.gradle(.kts)`: set `minSdk = 23` (secure storage + Razorpay).

`android/app/src/main/AndroidManifest.xml` – inside `<manifest>` add
`<uses-permission android:name="android.permission.INTERNET"/>` and on `<application>` add
`android:usesCleartextTraffic="true"` (development over plain HTTP only; remove for production).

## 3. Backend reachability from your phone
```bash
python manage.py runserver 0.0.0.0:8000   # add your laptop LAN IP to ALLOWED_HOSTS
```
Phone and laptop must be on the same Wi-Fi.

## 4. Run
```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_LAPTOP_LAN_IP:8000 \
  --dart-define=RAZORPAY_KEY=rzp_test_xxxxxxxx
```
(Android emulator default is `http://10.0.2.2:8000`.)

## Authentication note
The backend reads the token from a cookie named `Token`. The Dio interceptor sends
`Cookie: Token=<token>` manually (plus `Authorization: Token <token>`), so no backend change is needed.

## Location, maps and links (added)
In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`, also add:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>
</queries>
```
Needed for "Use my current location" (provider) and for Directions / Email host / social links (customer).
