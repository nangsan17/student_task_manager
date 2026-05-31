import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import 'register_screen.dart';
import '../dashboard/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().loginUser(email: _emailCtrl.text, password: _passCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendly(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    if (_emailCtrl.text.isEmpty) { setState(() => _error = 'Enter your email first'); return; }
    try {
      await context.read<AuthService>().resetPassword(_emailCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendly(e.toString()));
    }
  }

  String _friendly(String e) {
    if (e.contains('user-not-found'))        return 'No account found with this email.';
    if (e.contains('wrong-password'))        return 'Incorrect password. Try again.';
    if (e.contains('invalid-credential'))    return 'Invalid email or password.';
    if (e.contains('network-request-failed'))return 'No internet connection.';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Container(width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 34),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
            const SizedBox(height: 24),
            Text('Welcome back!', style: Theme.of(context).textTheme.displayLarge).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text('Sign in to manage your tasks', style: Theme.of(context).textTheme.bodyMedium).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 40),

            if (_error != null)
              Container(
                width: double.infinity, margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                ]),
              ).animate().shakeX(),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : (!v.contains('@') ? 'Enter a valid email' : null),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : (v.length < 6 ? 'Minimum 6 characters' : null),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgot,
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
            ).animate().fadeIn(delay: 300.ms),

            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Sign In'),
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ", style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ]).animate().fadeIn(delay: 400.ms),
          ],
        )),
      )),
    );
  }
}
