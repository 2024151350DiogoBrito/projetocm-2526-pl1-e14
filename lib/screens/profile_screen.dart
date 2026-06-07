import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// ecrã de perfil
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _showEditProfileDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController(
          text: user?.displayName ?? user?.email?.split('@').first ?? '',
        );

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'EDIT PROFILE',
              style: TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  controller: nameController,
                  label: 'NAME',
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.length < 2) {
                          _showMessage('Introduz um nome válido.');
                          return;
                        }

                        setDialogState(() => isLoading = true);
                        try {
                          await AuthService().updateProfile(name: name);

                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          setState(() {});
                          _showMessage('Perfil atualizado.');
                        } catch (e) {
                          _showMessage(e.toString());
                          if (dialogContext.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SAVE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final currentController = TextEditingController();
        final newController = TextEditingController();
        bool currentPasswordVisible = false;
        bool newPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'CHANGE PASSWORD',
              style: TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  controller: currentController,
                  label: 'CURRENT PASSWORD',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !currentPasswordVisible,
                  passwordVisible: currentPasswordVisible,
                  onTogglePassword: () {
                    setDialogState(
                      () => currentPasswordVisible = !currentPasswordVisible,
                    );
                  },
                ),
                const SizedBox(height: 14),
                _dialogField(
                  controller: newController,
                  label: 'NEW PASSWORD',
                  icon: Icons.lock_reset_rounded,
                  obscureText: !newPasswordVisible,
                  passwordVisible: newPasswordVisible,
                  onTogglePassword: () {
                    setDialogState(
                      () => newPasswordVisible = !newPasswordVisible,
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await AuthService().changePassword(
                            currentPassword: currentController.text.trim(),
                            newPassword: newController.text.trim(),
                          );

                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _showMessage('Password alterada.');
                        } catch (e) {
                          _showMessage(e.toString());
                          if (dialogContext.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SAVE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool? passwordVisible,
    VoidCallback? onTogglePassword,
  }) => TextField(
    controller: controller,
    obscureText: obscureText,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryRed),
      suffixIcon: onTogglePassword == null || passwordVisible == null
          ? null
          : IconButton(
              tooltip: passwordVisible
                  ? 'Esconder password'
                  : 'Mostrar password',
              onPressed: onTogglePassword,
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF7C7D84),
              ),
            ),
    ),
  );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryRed),
    );
  }

  // mostra a janela de créditos da equipa
  void _showCreditsDialog() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Center(
        child: Text(
          'CRÉDITOS DO PROJETO',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),

          // nossos nomes e números
          _buildCreditName("1. Diogo Brito", "2024151350"),
          _buildCreditName("2. Diogo Gomes", "2024148451"),
          _buildCreditName("3. Guilherme Garcia", "202300160"),
          _buildCreditName("4. Rafael Junqueira", "2024151531"),

          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),

          // turma e professor
          _buildInfoRow("Turma:", "PL4"),
          _buildInfoRow("Disciplina:", "Computação Móvel (CM)"),
          _buildInfoRow("Curso:", "LEI 25/26"),
          _buildInfoRow("Professor:", "David Sanguinetti"),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "IPS - EST SETÚBAL",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'FECHAR',
            style: TextStyle(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  // constrói a interface do perfil
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const SizedBox(height: 70),

          _buildMyProfileTitle(),

          const SizedBox(height: 40),

          _buildAvatarSection(),

          const SizedBox(height: 50),

          _buildSectionHeader("ACCOUNT SETTINGS"),

          // linha com switch de notificações
          _buildProfileTile(
            icon: Icons.notifications_none_rounded,
            title: "NOTIFICATIONS",
            subtitle: "ALERTS FOR NEW MOVIES AND PREMIERES",
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeThumbColor: Colors.white,
              activeTrackColor: AppTheme.primaryRed,
            ),
          ),

          _buildProfileTile(
            icon: Icons.lock_outline_rounded,
            title: "SECURITY",
            subtitle: "CHANGE AND RECOVER PASSWORD",
            hasChevron: true,
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 30),

          _buildSectionHeader("APPLICATION"),

          // linha que abre o popup dos créditos
          _buildProfileTile(
            icon: Icons.info_outline_rounded,
            title: "ABOUT AND CREDITS",
            subtitle: "PROJECT AND TEAM INFORMATION",
            hasChevron: true,
            onTap: _showCreditsDialog,
          ),

          const SizedBox(height: 40),

          _buildSignOutButton(),

          const SizedBox(height: 30),

          const Text(
            "VERSION 1.0",
            style: TextStyle(
              color: Colors.white12,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    ),
  );

  // título principal à esquerda
  Widget _buildMyProfileTitle() => Align(
    alignment: Alignment.centerLeft,
    child: RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -1.5,
        ),
        children: [
          TextSpan(
            text: 'MY ',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'PROFILE',
            style: TextStyle(color: AppTheme.primaryRed),
          ),
        ],
      ),
    ),
  );

  // zona da foto e dados do utilizador
  Widget _buildAvatarSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E26),
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 60,
                  color: AppTheme.primaryRed,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          (user?.displayName ?? user?.email?.split('@').first ?? "USER")
              .toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          user?.email ?? "NO EMAIL",
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // cabeçalho de secção do menu
  Widget _buildSectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  // componente para as linhas do menu
  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(20),
    ),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox(),
          if (hasChevron)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
        ],
      ),
    ),
  );

  // botão para terminar sessão
  Widget _buildSignOutButton() => Container(
    width: double.infinity,
    height: 65,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5)),
    ),
    child: TextButton.icon(
      onPressed: () async {
        await AuthService().logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      icon: const Icon(Icons.logout_rounded, color: AppTheme.primaryRed),
      label: const Text(
        "SIGN OUT",
        style: TextStyle(
          color: AppTheme.primaryRed,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );

  // helper para nomes no popup
  Widget _buildCreditName(String name, String num) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          num,
          style: const TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  // helper para informações no popup
  Widget _buildInfoRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text("$l ", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
