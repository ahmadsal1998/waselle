# Call System App State Testing Guide

This document provides comprehensive testing instructions for verifying that the call system works correctly across all app states (background, terminated, minimized).

## Implementation Overview

The call system now includes:

1. **App Lifecycle Service** - Monitors app state changes and handles calls when app is in background/terminated
2. **Global Call Listeners** - Socket.IO listeners that work regardless of app state
3. **Pending Call Storage** - Stores incoming call data when app is terminated for recovery when app resumes
4. **Global Navigator Key** - Allows navigation to call screen even when app is launched from terminated state

## Test Scenarios

### Scenario 1: App in Background

**Setup:**
1. Launch the receiver's app (user or driver)
2. Put the app in background (press home button or switch to another app)
3. Keep the app running in background (don't force close)

**Test Steps:**
1. Caller initiates a call from their device
2. **Expected Result:**
   - ✅ Incoming call notification appears immediately (via Socket.IO)
   - ✅ When receiver taps "Accept", app brings itself to foreground
   - ✅ Zego call screen opens instantly
   - ✅ No loading screen, no black screen, no delays
   - ✅ Call connects successfully

**Verification:**
- Check that incoming call dialog appears while app is in background
- Verify app comes to foreground when "Accept" is tapped
- Confirm call screen opens without delays
- Test that call audio works correctly

---

### Scenario 2: App Completely Closed (Terminated/Killed State)

**Setup:**
1. Launch the receiver's app
2. Force close the app completely (swipe away from recent apps or use "Force Stop")
3. Verify app is fully terminated

**Test Steps:**
1. Caller initiates a call from their device
2. **Expected Result:**
   - ⚠️ **Note:** Currently relies on Socket.IO which disconnects when app is terminated
   - ⚠️ **Future Enhancement:** Push notifications needed for true terminated state support
   - ✅ When app is manually opened and socket reconnects, pending calls are checked
   - ✅ If call data was stored, app navigates to call screen

**Current Behavior:**
- Socket.IO disconnects when app is terminated
- When app is reopened, socket reconnects
- App checks for pending calls stored in SharedPreferences
- If pending call exists, app attempts to handle it

**Future Enhancement Required:**
- Implement Firebase Cloud Messaging (FCM) push notifications
- Send push notification when call is initiated
- Handle notification tap to launch app and navigate to call screen

---

### Scenario 3: App Minimized

**Setup:**
1. Launch the receiver's app
2. Minimize the app (press home button, but keep it in recent apps)

**Test Steps:**
1. Caller initiates a call from their device
2. **Expected Result:**
   - ✅ Incoming call notification appears normally
   - ✅ When receiver taps "Accept", app restores instantly from minimized state
   - ✅ Call UI opens with no issues
   - ✅ Call connects successfully

**Verification:**
- Verify notification appears while app is minimized
- Confirm app restores smoothly when accepting call
- Test that call screen appears correctly
- Verify call functionality works

---

### Scenario 4: App State Transitions

**Test Steps:**
1. **Background → Foreground:**
   - Put app in background
   - Receive call while in background
   - Accept call
   - Verify app transitions smoothly to foreground

2. **Terminated → Launched:**
   - Force close app
   - Wait for socket to reconnect when app is opened
   - Verify pending calls are checked
   - Test that stored calls are handled correctly

3. **Minimized → Restored:**
   - Minimize app
   - Receive call
   - Accept call
   - Verify app restores and call screen appears

---

## Must-Have Behaviors (All App States)

Regardless of app state, the receiver MUST be able to:

### ✅ Accept the Call
- Incoming call dialog/notification must be visible
- "Accept" button must work
- App must navigate to call screen after accepting

### ✅ Reject the Call
- "Reject" button must work
- Caller must be notified of rejection
- Dialog must close properly

### ✅ Enter Zego Room Immediately
- After accepting, must join Zego room without delay
- No long loading screens
- No black screens
- No timeouts
- Room must connect successfully

### ❌ Must NOT Happen
- Long loading screen (> 2 seconds)
- Black screen
- Timeout errors
- Failure to join room
- Notification not arriving (when app is in background/minimized)
- App opening without navigating to call screen

---

## Testing Checklist

### Driver App Testing
- [ ] Background state - incoming call works
- [ ] Terminated state - call recovery works
- [ ] Minimized state - call works
- [ ] Accept call - navigates correctly
- [ ] Reject call - works correctly
- [ ] Call connects successfully
- [ ] Audio works correctly

### User App Testing
- [ ] Background state - incoming call works
- [ ] Terminated state - call recovery works
- [ ] Minimized state - call works
- [ ] Accept call - navigates correctly
- [ ] Reject call - works correctly
- [ ] Call connects successfully
- [ ] Audio works correctly

### Cross-App Testing
- [ ] Driver calls user - all states work
- [ ] User calls driver - all states work
- [ ] Both apps in background - calls work
- [ ] One app terminated, one active - calls work

---

## Debugging Tips

### Check Logs
Look for these log messages:
- `📞 Global incoming call listener triggered` - Global listener received call
- `📞 Incoming call received` - Call handling started
- `💾 Stored pending call` - Call stored for recovery
- `🔄 Found pending call` - Pending call found on app resume
- `📱 App resumed, checking for pending calls` - App lifecycle detected

### Common Issues

1. **Call not appearing in background:**
   - Check Socket.IO connection status
   - Verify app lifecycle service is initialized
   - Check that global listeners are set up

2. **Call not recovering after app restart:**
   - Check SharedPreferences for pending call data
   - Verify socket reconnects properly
   - Check that pending call check runs on app resume

3. **Context errors:**
   - Verify global navigator key is set up
   - Check that context is available when handling calls
   - Ensure app is fully initialized before handling calls

---

## Technical Implementation Details

### Files Modified/Created

1. **App Lifecycle Service** (`lib/services/app_lifecycle_service.dart`)
   - Monitors app lifecycle state
   - Sets up global call listeners
   - Stores/recovers pending calls
   - Handles calls when app resumes

2. **Zego Call Service** (`lib/services/zego_call_service.dart`)
   - Updated to use global navigator key when context not available
   - Supports handling calls without explicit context

3. **Socket Service** (`lib/services/socket_service.dart`)
   - Updated to support multiple listeners per event
   - Ensures global and screen-specific listeners both work

4. **Main App** (`lib/main.dart`)
   - Initializes app lifecycle service
   - Sets up global navigator key

---

## Future Enhancements

1. **Push Notifications (FCM)**
   - Implement Firebase Cloud Messaging
   - Send push notifications for incoming calls
   - Handle notification taps to launch app and navigate to call

2. **CallKit Integration (iOS)**
   - Native call UI for iOS
   - Better integration with iOS call system
   - Works even when app is terminated

3. **Background Audio**
   - Ensure audio continues when app is in background
   - Handle audio session interruptions

4. **Call State Persistence**
   - Store active call state
   - Recover call state after app restart
   - Handle call reconnection

---

## Notes

- Current implementation relies on Socket.IO which maintains connection when app is in background (on most devices)
- True terminated state support requires push notifications (FCM)
- The system stores pending calls in SharedPreferences for recovery
- Global navigator key allows navigation even when app is launched from terminated state
- Multiple listeners are supported to ensure calls are handled regardless of which listener receives the event

