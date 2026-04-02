import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/theme/app_gradients.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final isLoggedIn = await ApiClient.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        // Verificar se é motorista
        try {
          final user = await ApiClient.getCurrentUser();
          if (user != null && user['user_type'] == 'DRIVER') {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            await ApiClient.logout();
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AppColors.metyPurple.withOpacity(0.2),
              AppColors.black,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: AppGradients.driver,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.metyPurple.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.drive_eta_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'METY DRIVER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Parceiro de transporte',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    color: AppColors.metyPurple,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
