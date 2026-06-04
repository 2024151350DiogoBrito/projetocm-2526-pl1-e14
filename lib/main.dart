import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



// função principal
void main() async {
  // inicialização do flutter
  WidgetsFlutterBinding.ensureInitialized();

  // barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // bloqueio da orientação vertical
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MovieNestApp());
}

// configuração global
class MovieNestApp extends StatelessWidget {
  const MovieNestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MovieNest',
    // remove banner de debug
    debugShowCheckedModeBanner: false,
    // tema da aplicação
    theme: AppTheme.darkTheme,
    // ecrã inicial
    home: const SplashScreen(),
  );
}
