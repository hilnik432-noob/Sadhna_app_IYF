// Generated from sadhana-app-iyf Firebase project
// DO NOT edit manually — re-run connect_firebase.js to regenerate

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAzESBg-02XmC6CxqmjZXls2hitxgxlySE',
    appId:             '1:554264804185:web:aea6718a94c75bffc52a48',
    messagingSenderId: '554264804185',
    projectId:         'sadhana-app-iyf',
    authDomain:        'sadhana-app-iyf.firebaseapp.com',
    storageBucket:     'sadhana-app-iyf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAzESBg-02XmC6CxqmjZXls2hitxgxlySE',
    appId:             '1:554264804185:android:284a37a9d92275bfc52a48',
    messagingSenderId: '554264804185',
    projectId:         'sadhana-app-iyf',
    storageBucket:     'sadhana-app-iyf.firebasestorage.app',
  );

  // iOS: add an iOS app in Firebase Console to get these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyAzESBg-02XmC6CxqmjZXls2hitxgxlySE',
    appId:             '1:554264804185:ios:PLACEHOLDER',
    messagingSenderId: '554264804185',
    projectId:         'sadhana-app-iyf',
    storageBucket:     'sadhana-app-iyf.firebasestorage.app',
    iosBundleId:       'com.iyf.sadhanaApp',
  );
}
