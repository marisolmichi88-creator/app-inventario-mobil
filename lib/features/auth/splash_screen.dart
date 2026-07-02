import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon.png', 
                  height: 120, 
                  width: 120, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2, size: 100, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
