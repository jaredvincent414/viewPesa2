//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Comment out Firebase import

//class NotificationService {
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance; // Comment out FCM instance
 // final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

 // Future<void> initialize() async {
    // await _fcm.requestPermission(); // Comment out FCM permission request
   // const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
   // const initializationSettings = InitializationSettings(android: androidSettings);
   // await _localNotifications.initialize(initializationSettings);

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) { // Comment out foreground message listener
    //   _showNotification(message);
    // });

    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); // Comment out background message handler

    // String? token = await _fcm.getToken(); // Comment out FCM token retrieval
    // print('FCM Token: $token'); // Save to server for targeting
  //}

  // Update _showNotification to handle local notifications without RemoteMessage
 // Future<void> _showNotification([String? title, String? body]) async {
   // const androidDetails = AndroidNotificationDetails(
     // 'transaction_channel',
      //'Transactions',
      //importance: Importance.max,
     // priority: Priority.high,
  //  );
   // const notificationDetails = NotificationDetails(android: androidDetails);

   // await _localNotifications.show(
     // DateTime.now().hashCode, // Use timestamp-based ID
     // title ?? 'New Transaction',
     // body ?? 'A new transaction has been recorded.',
     // notificationDetails,
   // );
 // }
//}

// Comment out background handler
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Background message: ${message.messageId}');
// }