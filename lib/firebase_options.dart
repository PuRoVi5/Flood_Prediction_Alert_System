import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
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
    apiKey: 'AIzaSyCZrTBR1e9RAbBEPkQBtfyzYIFl7KpH53s',
    appId: '1:695934730730:web:a159d60f09355102acf293',
    messagingSenderId: '695934730730',
    projectId: 'floodalertsystem-1',
    authDomain: 'floodalertsystem-1.firebaseapp.com',
    storageBucket: 'floodalertsystem-1.appspot.com',
    measurementId: 'G-XFBBH33H21',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZrTBR1e9RAbBEPkQBtfyzYIFl7KpH53s',
    appId:
        '1:695934730730:android:3d969796e83407e7acf293', // আপনার Android App ID
    messagingSenderId: '695934730730',
    projectId: 'floodalertsystem-1',
    storageBucket: 'floodalertsystem-1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZrTBR1e9RAbBEPkQBtfyzYIFl7KpH53s',
    appId: '1:695934730730:ios:your_ios_id', // iOS অ্যাপ এড করলে এটি পাবেন
    messagingSenderId: '695934730730',
    projectId: 'floodalertsystem-1',
    storageBucket: 'floodalertsystem-1.appspot.com',
    iosBundleId: 'com.purovi.floodalert',
  );
}
