// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoq_1KLlLAx3ILJMqYD-Vcc761mp_aIDY',
    appId: '1:885679973478:web:e4b8d4262de0ad7112f9a7',
    messagingSenderId: '885679973478',
    projectId: 'codeshastraxi',
    authDomain: 'codeshastraxi.firebaseapp.com',
    storageBucket: 'codeshastraxi.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgmS4_NTwyWCZcJWbAs2Ftfh34GnMVleQ',
    appId: '1:885679973478:android:e362dc145a7a7f6612f9a7',
    messagingSenderId: '885679973478',
    projectId: 'codeshastraxi',
    storageBucket: 'codeshastraxi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBcfTe364bLz8ThiKUi-PJn5mdnqRqqG4',
    appId: '1:885679973478:ios:f72c59e41990aba312f9a7',
    messagingSenderId: '885679973478',
    projectId: 'codeshastraxi',
    storageBucket: 'codeshastraxi.firebasestorage.app',
    iosBundleId: 'com.example.codeshastraxiOverloadOblivion',
  );
}
