import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import './main.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            themeMode: ThemeMode.system,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Login(),
          );
        }
        return HG_App();
      },
    );
  }
}

class Login extends StatelessWidget {
  const Login({Key? key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        GoogleProvider(clientId: "450750580474-f7t2jfdafu3r5nsqjpvep3f9aj8psbmg.apps.googleusercontent.com450750580474-f7t2jfdafu3r5nsqjpvep3f9aj8psbmg.apps.googleusercontent.com450750580474-f7t2jfdafu3r5nsqjpvep3f9aj8psbmg.apps.googleusercontent.com"),
      ],
      subtitleBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: action == AuthAction.signIn
              ? const Text('Welcome to Home Genie, please sign in!')
              : const Text('Please create a (Beta) Home Genie Account'),
        );
      },
      footerBuilder: (context, action) {
        return const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'App is still in testing (Beta)',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
}
