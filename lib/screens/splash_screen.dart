import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import '../theme/app_theme.dart';

// ecrã de carregamento inicial
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // corre logo ao abrir o ecrã
  @override
  void initState() {
    super.initState();
    // espera 3 segundos para mudar de ecrã
    Future.delayed(const Duration(seconds: 3), () {
      // verifica se o ecrã ainda está ativo
      if (mounted) {
        // vai para o login e apaga a splash da memória
        final user = FirebaseAuth.instance.currentUser;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                user == null ? const LoginScreen() : const MainNavigation(),
          ),
        );
      }
    });
  }

  // desenha o ecrã
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: _radialBackground(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // logo da aplicação
          Image.asset('assets/splashlogo.png', height: 100),
          const SizedBox(height: 8),
          _buildGradientBar(),
        ],
      ),
    ),
  );

  // fundo com degradê circular
  BoxDecoration _radialBackground() => const BoxDecoration(
    gradient: RadialGradient(
      radius: 0.6,
      colors: [Color(0xFF2B0002), AppTheme.deepBlack],
    ),
  );

  // linha decorativa com cores
  Widget _buildGradientBar() => Container(
    width: 100,
    height: 2,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(1),
      gradient: const LinearGradient(
        colors: [AppTheme.primaryRed, Colors.white],
      ),
    ),
  );
}
