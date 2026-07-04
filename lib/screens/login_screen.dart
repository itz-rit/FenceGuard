import 'package:fenceguard/screens/email_login_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget{
  const LoginScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:const BoxDecoration(
          gradient: LinearGradient(
            begin:Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child:Column(
            children: [
              const Spacer(),
              //App logo
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    fit: BoxFit.contain,
                  ),
                  ),


              ),
              const SizedBox(height: 16),
              //App Name
              const Text(
                "FenceGuard",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                "Smart Fence Monitoring System",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),

              //White Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Login to your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ), 
                     const SizedBox(height: 24), 

                     //Google Login 
                     OutlinedButton.icon(
                      onPressed: () async{
                        final user = await AuthService().signInWithGoogle();

                        if(user != null && context.mounted){
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text(
                        "Continue with Google",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.black,
                      ),
                    ),
                      const SizedBox(height: 12),

                      //Email Login
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                     
                      child: const Text(
                        "Continue with Email",
                        style: TextStyle(fontSize: 16),
                      ),
                     ),

                     const SizedBox(height: 16),
                     const Text(
                      "By continuing , you agree to our Terms & Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                     ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}