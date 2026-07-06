import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_shadows.dart';

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
                boxShadow: AppShadows.iconGlow(Colors.white),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/icon.svg', 
                  height: 120, 
                  width: 120, 
                  fit: BoxFit.contain,
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
