// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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
    apiKey: 'AIzaSyBn_623X-um8-Vetgh2fMZ2EsBEdlS1ZR0',
    appId: '1:350533039792:web:9574d5d2f36b2351ca6d75',
    messagingSenderId: '350533039792',
    projectId: 'messenger-8b55b',
    authDomain: 'messenger-8b55b.firebaseapp.com',
    databaseURL: 'https://messenger-8b55b-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'messenger-8b55b.appspot.com',
    measurementId: 'G-FTCTP48L2Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMXr_FF5W4FMXkXEHr7n_Szwi9Fmu5u0o',
    appId: '1:350533039792:android:4b3b218c2fc7064dca6d75',
    messagingSenderId: '350533039792',
    projectId: 'messenger-8b55b',
    databaseURL: 'https://messenger-8b55b-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'messenger-8b55b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCeaSuqwc-Ihc-tIliEObpttJU9gU6x5Wo',
    appId: '1:350533039792:ios:185b45d7f639f880ca6d75',
    messagingSenderId: '350533039792',
    projectId: 'messenger-8b55b',
    databaseURL: 'https://messenger-8b55b-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'messenger-8b55b.appspot.com',
    androidClientId: '350533039792-1sfqaur7g6shao813ifor425nllpid0o.apps.googleusercontent.com',
    iosClientId: '350533039792-bd187vp5989qh2epat83aed3et169qff.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterChatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCeaSuqwc-Ihc-tIliEObpttJU9gU6x5Wo',
    appId: '1:350533039792:ios:185b45d7f639f880ca6d75',
    messagingSenderId: '350533039792',
    projectId: 'messenger-8b55b',
    databaseURL: 'https://messenger-8b55b-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'messenger-8b55b.appspot.com',
    androidClientId: '350533039792-1sfqaur7g6shao813ifor425nllpid0o.apps.googleusercontent.com',
    iosClientId: '350533039792-bd187vp5989qh2epat83aed3et169qff.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterChatApp',
  );
}
