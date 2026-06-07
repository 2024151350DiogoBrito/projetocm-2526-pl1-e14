import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

// ecrã de login da aplicação
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // controla se mostra login ou registo
  bool isSignIn = true;

  // controladores dos campos
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  // desenha a interface principal
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: _backgroundGradient(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // logo da app
            Image.asset('assets/splashlogo.png', height: 100),

            const SizedBox(height: 60),

            _buildAuthCard(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    ),
  );

  // fundo com brilho avermelhado
  BoxDecoration _backgroundGradient() => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0, -0.5),
      radius: 1.2,
      colors: [AppTheme.primaryRed.withValues(alpha: 0.15), AppTheme.deepBlack],
    ),
  );

  // card que contém o formulário
  Widget _buildAuthCard() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF16171D).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // abas para trocar de modo
        Row(
          children: [
            _tab("SIGN IN", isSignIn),
            const SizedBox(width: 25),
            _tab("SIGN UP", !isSignIn),
          ],
        ),

        const SizedBox(height: 40),

        if (!isSignIn) ...[
          _label("NAME"),

          const SizedBox(height: 10),

          _field(
            controller: _nameController,
            hint: "O teu nome",
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 25),
        ],

        _label("EMAIL ADDRESS"),

        const SizedBox(height: 10),

        _field(
          controller: _emailController,
          hint: "example@gmail.com",
          icon: Icons.mail_outline_rounded,
        ),

        const SizedBox(height: 25),

        _label("PASSWORD"),

        const SizedBox(height: 10),

        _field(
          controller: _passwordController,
          hint: "••••••••••••",
          icon: Icons.lock_outline_rounded,
          isPass: true,
        ),

        const SizedBox(height: 40),

        _loginButton(),
      ],
    ),
  );

  // componente das abas de seleção
  Widget _tab(String label, bool active) => GestureDetector(
    onTap: () => setState(() => isSignIn = label == "SIGN IN"),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.primaryRed : const Color(0xFF4B4C52),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        if (active)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 40,
            height: 2,
            color: AppTheme.primaryRed,
          ),
      ],
    ),
  );

  // legenda pequena acima dos campos
  Widget _label(String txt) => Text(
    txt,
    style: const TextStyle(
      color: Color(0xFF5A5B63),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );

  // estrutura dos campos de texto
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D0E12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
    ),
    child: TextField(
      controller: controller,
      obscureText: isPass && !_passwordVisible,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF37383D)),
        prefixIcon: Icon(icon, color: const Color(0xFF37383D), size: 22),
        suffixIcon: isPass
            ? IconButton(
                tooltip: _passwordVisible
                    ? 'Esconder password'
                    : 'Mostrar password',
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF5A5B63),
                  size: 22,
                ),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    ),
  );

  // botão para entrar na aplicação
  Widget _loginButton() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
              try {
                setState(() => _isLoading = true);

                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                _validateFields(name, email, password);

                if (isSignIn) {
                  await AuthService().login(email, password);
                } else {
                  await AuthService().register(name, email, password);
                }

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppTheme.primaryRed,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignIn ? "ENTER THE NEST" : "CREATE ACCOUNT",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
    ),
  );

  void _validateFields(String name, String email, String password) {
    if (!isSignIn && name.length < 2) {
      throw AuthServiceException(
        'Introduz um nome com pelo menos 2 caracteres.',
      );
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      throw AuthServiceException('Introduz um email válido.');
    }

    if (password.isEmpty) {
      throw AuthServiceException('Introduz a tua palavra-passe.');
    }

    if (!isSignIn && password.length < 6) {
      throw AuthServiceException(
        'A palavra-passe deve ter pelo menos 6 caracteres.',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
