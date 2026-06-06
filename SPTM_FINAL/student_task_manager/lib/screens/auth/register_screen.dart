import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../dashboard/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false, _obscureP = true, _obscureC = true;
  String? _error;
  String _course = 'Bachelor of Science (Hons) in Software Engineering';

  static const _courses = [
    'Bachelor of Science (Hons) in Software Engineering',
    'Bachelor of Science (Hons) in Computer Science (AI)',
    'Bachelor of Science (Hons) in Information Technology',
    'Bachelor of Engineering (Hons)',
    'Diploma of Engineering',
    'Foundation of Business',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().registerUser(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          course: _course);
      if (!mounted) return;
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

  String _friendly(String e) {
    if (e.contains('email-already-in-use'))
      return 'This email is already registered.';
    if (e.contains('invalid-email')) return 'Please enter a valid email.';
    if (e.contains('weak-password'))
      return 'Password too weak. Use 6+ characters.';
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary, size: 20)),
          title: const Text('Create Account')),
      body: SafeArea(
          child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Join SPTM',
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .fadeIn(),
              const SizedBox(height: 4),
              Text('Start managing your tasks today',
                      style: Theme.of(context).textTheme.bodyMedium)
                  .animate()
                  .fadeIn(delay: 80.ms),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13))),
                    ])).animate().shakeX(),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Email is required'
                    : !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
              ).animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _course,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Course',
                    prefixIcon: Icon(Icons.school_outlined)),
                items: _courses
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _course = v!),
              ).animate().fadeIn(delay: 180.ms),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscureP,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                        icon: Icon(_obscureP
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureP = !_obscureP))),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Password is required'
                    : v.length < 6
                        ? 'Min 6 characters'
                        : null,
              ).animate().fadeIn(delay: 220.ms),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureC,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                        icon: Icon(_obscureC
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureC = !_obscureC))),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please confirm password'
                    : v != _passCtrl.text
                        ? 'Passwords do not match'
                        : null,
              ).animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: _loading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text('Create Account',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                  )).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign In',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700))),
              ]).animate().fadeIn(delay: 340.ms),
              const SizedBox(height: 24),
            ])),
      )),
    );
  }
}
