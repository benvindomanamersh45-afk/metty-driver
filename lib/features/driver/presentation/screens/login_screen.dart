import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/theme/app_gradients.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Preencha todos os campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String phone = '+244${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}';
      
      await ApiClient.login(phone, _passwordController.text);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError('Telefone ou senha incorretos');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Background gradiente
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.metyPurple.withOpacity(0.15),
                    AppColors.black,
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppGradients.driver,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.metyPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.drive_eta_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Título
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'METY DRIVER',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Faça parte da nossa frota',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Formulário
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Telefone
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.phone_rounded,
                                color: AppColors.metyPurple,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '+244',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '987654321',
                                    hintStyle: TextStyle(color: Colors.white30),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Senha
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.lock_rounded,
                                color: AppColors.metyPurple,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '123456',
                                    hintStyle: TextStyle(color: Colors.white30),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.metyPurple,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Botão
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.metyPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Rodapé
                        Column(
                          children: [
                            Text(
                              'DESENVOLVIDO POR',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.metyPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.metyPurple.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.code_rounded,
                                        color: AppColors.metyPurple,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Katokampos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.metyPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.metyBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.metyBlue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.developer_board_rounded,
                                        color: AppColors.metyBlue,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'MBSoft',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.metyBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '© 2025 METY Driver - Todos os direitos reservados',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
