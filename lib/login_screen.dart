import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future submit() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        UserCredential user =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.user!.uid)
            .get();

        String role = doc['role'];

        print("ROLE: $role"); // DEBUG

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(role: role),
          ),
        );
      } else {
        // 🆕 SIGNUP
        UserCredential user =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // 💾 SAVE USER DATA IN FIRESTORE
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.user!.uid)
            .set({
          "email": emailController.text.trim(),
          "role": "member", // default role
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup successful! Please login.")),
        );

        setState(() {
          isLogin = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login / Signup")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submit,
                    child: Text(isLogin ? "Login" : "Signup"),
                  ),

            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin
                  ? "Create new account"
                  : "Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}