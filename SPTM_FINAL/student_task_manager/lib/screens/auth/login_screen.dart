import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import 'register_screen.dart';
import '../dashboard/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus(); // dismiss keyboard fast
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AuthService>()
          .loginUser(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      // Replace entire stack — no animation delay
      Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(e.toString());
      });
    }
  }

  Future<void> _forgot() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    try {
      await context.read<AuthService>().resetPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      _showSnack('Password reset email sent!', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendly(e.toString()));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  String _friendly(String e) {
    if (e.contains('user-not-found') || e.contains('invalid-credential'))
      return 'Invalid email or password.';
    if (e.contains('wrong-password')) return 'Incorrect password.';
    if (e.contains('network-request-failed')) return 'No internet connection.';
    if (e.contains('too-many-requests'))
      return 'Too many attempts. Try again later.';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.08),

                    // Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.task_alt_rounded,
                          color: Colors.white, size: 30),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 20),
                    Text('Welcome back!',
                            style: Theme.of(context).textTheme.headlineMedium)
                        .animate()
                        .fadeIn(delay: 80.ms),
                    const SizedBox(height: 4),
                    Text('Sign in to manage your tasks',
                            style: Theme.of(context).textTheme.bodyMedium)
                        .animate()
                        .fadeIn(delay: 120.ms),
                    const SizedBox(height: 32),

                    if (_error != null)
                      _ErrorBanner(_error!).animate().fadeIn().shakeX(),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Email is required'
                          : !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ).animate().fadeIn(delay: 160.ms),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure))),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : v.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                    ).animate().fadeIn(delay: 200.ms),

                    Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            onPressed: _forgot,
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)))),

                    // Sign In button — iOS-style loading state
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white)
                            : const Text('Sign In',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                      ),
                    ).animate().fadeIn(delay: 240.ms),
                    const SizedBox(height: 28),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: const Text('Sign Up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700))),
                    ]).animate().fadeIn(delay: 280.ms),

                    SizedBox(height: size.height * 0.04),
                  ],
                )),
          ),
        ),
      )),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.danger, fontSize: 13))),
      ]));
}
