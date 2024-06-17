import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyARMQg9NlDX5lw3SzdcQrmvmChX2--y_BI",
            authDomain: "testing-35581.firebaseapp.com",
            projectId: "testing-35581",
            storageBucket: "testing-35581.appspot.com",
            messagingSenderId: "947637356399",
            appId: "1:947637356399:web:8d38120265c88eb8410a9a",
            measurementId: "G-JF8T6XS3ZS"));
  } else {
    Firebase.initializeApp();
  }

  runApp(Firebaseapp());
}

class Firebaseapp extends StatelessWidget {
  const Firebaseapp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
