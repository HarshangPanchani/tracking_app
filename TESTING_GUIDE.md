# 🧪 Complete Testing Guide - Company Tracker App

## 📋 Prerequisites

Before testing, make sure you have:
- ✅ Flutter installed and configured
- ✅ An Android device/emulator OR iOS device/simulator
- ✅ Firebase project set up (you already have this)
- ✅ A test user account in Firebase Authentication

---

## 🚀 Step-by-Step Testing Instructions

### **Step 1: Create a Test User in Firebase**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `companytracker-e1f3c`
3. Click **Authentication** in the left menu
4. Click **Users** tab
5. Click **Add User** button
6. Enter:
   - **Email**: `test@example.com` (or any email you want)
   - **Password**: `test123456` (at least 6 characters)
7. Click **Add User**

✅ **You now have a test account!**

---

### **Step 2: Choose Your Testing Device**

#### **Option A: Android Physical Device (RECOMMENDED for full testing)**

1. **Enable Developer Mode** on your Android phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Developer options will be enabled

2. **Enable USB Debugging**:
   - Go to Settings → Developer Options
   - Turn on "USB Debugging"

3. **Connect your phone** to your computer via USB

4. **Verify connection**:
   ```bash
   flutter devices
   ```
   You should see your device listed.

#### **Option B: Android Emulator**

1. Open Android Studio
2. Click **Device Manager** (phone icon on the right)
3. Click **Create Device**
4. Select a device (e.g., Pixel 5)
5. Download a system image (e.g., Android 13)
6. Click **Finish** and start the emulator

#### **Option C: Web (Limited - no background tracking)**

Web doesn't support background services, but you can test the UI:
```bash
flutter run -d chrome
```

---

### **Step 3: Run the App**

Open your terminal in the project directory and run:

#### **For Android Device:**
```bash
cd "c:\Users\panch\Desktop\tracking app\company_tracker"
flutter run
```

#### **For Specific Device:**
```bash
# First, check available devices
flutter devices

# Then run on specific device (copy the device ID from above)
flutter run -d <device-id>
```

**Example:**
```bash
flutter run -d emulator-5554
```

---

### **Step 4: Login to the App**

1. **App will launch** and show the Login Screen
2. **Enter credentials**:
   - Email: `test@example.com`
   - Password: `test123456`
3. **Click "Login"**
4. ✅ You should see the Home Screen

---

### **Step 5: Test Location Tracking**

#### **A. Grant Permissions**

1. **Click the large green "START DUTY" button**
2. **Permission dialog will appear** asking for location access
3. **Select "Allow all the time"** or "Allow while using the app"
   - For full background tracking, choose "Allow all the time"
4. If GPS is off, you'll see an error - **turn on GPS/Location**

#### **B. Start Tracking**

1. After granting permissions, the app will:
   - Show "Starting duty..." message
   - Start the background service
   - Button will turn **RED** and say "END DUTY"
   - You'll see a **notification** (Android): "Company Tracker - Tracking active..."

2. **Check the coordinates**:
   - A white card should appear showing:
     - **Latitude**: e.g., `37.421998`
     - **Longitude**: e.g., `-122.084000`

#### **C. Test Real-Time Updates**

**On Physical Device:**
1. **Walk around** (or drive) at least 10 meters
2. **Watch the coordinates update** in real-time
3. The notification should update with the timestamp

**On Emulator:**
1. In Android Studio, click the **three dots** (...) next to your emulator
2. Click **Location** in the left menu
3. **Enter new coordinates** or use the map
4. Click **Send**
5. Watch the app coordinates update

#### **D. Verify Firestore Updates**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Firestore Database**
3. You should see:
   ```
   users/
     └── {your-user-id}/
         ├── current_lat: 37.421998
         ├── current_lng: -122.084000
         ├── last_updated: [timestamp]
         ├── name: "test@example.com"
         ├── is_active: true
         └── location_history/
             └── [auto-id]/
                 ├── lat: 37.421998
                 ├── lng: -122.084000
                 └── timestamp: [timestamp]
   ```

#### **E. Test Background Tracking**

1. **Minimize the app** (press Home button)
2. **Check the notification** - it should still be there
3. **Move to a new location** (or simulate on emulator)
4. **Open Firebase Console** and refresh
5. ✅ **Verify new location** was saved even with app minimized

#### **F. Stop Tracking**

1. **Open the app again**
2. **Click the red "END DUTY" button**
3. The app will:
   - Show "Ending duty..." message
   - Stop the background service
   - Button turns **GREEN** and says "START DUTY"
   - Coordinates disappear
   - Notification disappears

4. **Check Firestore**:
   - `is_active` should now be `false`

---

### **Step 6: Test Logout**

1. **Click the logout icon** (top right)
2. If tracking is active, it will **auto-stop**
3. You'll be redirected to **Login Screen**
4. ✅ **Success!**

---

## 🔍 What to Look For (Testing Checklist)

### **✅ Login Screen**
- [ ] Email/password fields work
- [ ] Validation shows errors for invalid input
- [ ] Login button shows loading spinner
- [ ] Successful login navigates to Home Screen
- [ ] Error messages appear for wrong credentials

### **✅ Home Screen**
- [ ] User info displays correctly (name/email)
- [ ] Status message shows "Ready to start duty"
- [ ] Large green "START DUTY" button visible

### **✅ Start Duty Flow**
- [ ] Permission dialog appears
- [ ] After granting permission, tracking starts
- [ ] Button changes to red "END DUTY"
- [ ] Status changes to "Duty active - Tracking location"
- [ ] Coordinates appear and show real numbers
- [ ] Success snackbar appears
- [ ] Notification appears (Android)

### **✅ Real-Time Tracking**
- [ ] Coordinates update when location changes
- [ ] Notification updates with timestamp
- [ ] Firestore updates in real-time
- [ ] Location history grows with each update

### **✅ Background Tracking**
- [ ] App minimized, tracking continues
- [ ] Notification stays visible
- [ ] Firestore still receives updates
- [ ] Coordinates update when app reopened

### **✅ End Duty Flow**
- [ ] Button click stops tracking
- [ ] Button changes to green "START DUTY"
- [ ] Coordinates disappear
- [ ] Notification disappears
- [ ] Firestore `is_active` becomes `false`
- [ ] Success snackbar appears

### **✅ Logout**
- [ ] Auto-stops tracking if active
- [ ] Navigates to login screen
- [ ] Can log back in successfully

---

## 🐛 Common Issues & Solutions

### **Issue 1: "Location permission denied"**
**Solution:** 
- Go to phone Settings → Apps → Company Tracker → Permissions
- Enable Location → "Allow all the time"

### **Issue 2: "Location services are disabled"**
**Solution:**
- Turn on GPS/Location in phone settings
- Swipe down and tap Location icon

### **Issue 3: No coordinates showing**
**Solution:**
- Make sure you're testing on a physical device or properly configured emulator
- Check if GPS is enabled
- Try moving to a different location

### **Issue 4: Firestore not updating**
**Solution:**
- Check internet connection
- Verify Firebase configuration in `firebase_options.dart`
- Check Firestore security rules allow writes

### **Issue 5: App crashes on start**
**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### **Issue 6: Background service not working**
**Solution:**
- Make sure you're testing on Android (not web)
- Check that the service declaration is in AndroidManifest.xml
- Restart the app

---

## 📊 Expected Behavior Summary

| Action | Expected Result |
|--------|----------------|
| Login with valid credentials | Navigate to Home Screen |
| Click START DUTY | Request permissions → Start tracking → Show coordinates |
| Move 10+ meters | Coordinates update in app and Firestore |
| Minimize app | Tracking continues, notification visible |
| Click END DUTY | Stop tracking, hide coordinates, remove notification |
| Logout while tracking | Auto-stop tracking, then logout |

---

## 🎯 Quick Test Script

Here's a quick 5-minute test you can run:

```
1. ✅ Login (test@example.com / test123456)
2. ✅ Click START DUTY → Grant permissions
3. ✅ Verify coordinates appear
4. ✅ Check Firebase Console → See live data
5. ✅ Minimize app → Check notification
6. ✅ Reopen app → Coordinates still updating
7. ✅ Click END DUTY → Verify tracking stops
8. ✅ Logout → Back to login screen
```

---

## 📱 Testing Commands Reference

```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run with verbose logging
flutter run -v

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart (while app is running)
# Press 'R' in terminal

# Clear app data and restart
flutter clean
flutter pub get
flutter run

# View logs
flutter logs

# Stop running app
# Press 'q' in terminal
```

---

## 🎉 Success Criteria

Your app is working correctly if:

✅ You can login successfully  
✅ START DUTY button requests and receives permissions  
✅ Coordinates appear and update in real-time  
✅ Firebase Console shows live location data  
✅ Background tracking works when app is minimized  
✅ END DUTY stops tracking and clears data  
✅ Logout works and stops tracking automatically  

---

## 📞 Need Help?

If something isn't working:

1. **Check the terminal** for error messages
2. **Check Firebase Console** for authentication/database issues
3. **Check device permissions** in Settings
4. **Try `flutter clean` and rebuild**
5. **Check that GPS is enabled** on your device

---

## 🚀 Ready to Test!

**Start with:**
```bash
cd "c:\Users\panch\Desktop\tracking app\company_tracker"
flutter devices
flutter run
```

Then follow the steps above! Good luck! 🎯
