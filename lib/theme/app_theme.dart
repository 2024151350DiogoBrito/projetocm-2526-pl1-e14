import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// design system da aplicação
class AppTheme {
  // paleta de cores principal
  static const Color primaryRed = Color(0xFFE7000B);
  static const Color deepBlack = Color(0xFF0A0A0C);
  static const Color darkCard = Color(0xFF16171D);

  // definições do tema dark
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepBlack,
    primaryColor: primaryRed,

    // fontes e estilos de texto
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.kanit(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      titleLarge: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),

    // estilo dos campos de texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: _border(),
      // borda quando o campo está ativo
      enabledBorder: _border(Colors.white.withValues(alpha: 0.05)),
      hintStyle: const TextStyle(color: Color(0xFF374151), fontSize: 14),
    ),

    // estilo global dos botões
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        elevation: 10,
        // cor da sombra com transparência
        shadowColor: primaryRed.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  // função auxiliar para as bordas
  static OutlineInputBorder _border([Color color = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color),
      );
}
