import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
        color: AppColors.primary,
        light: AppColors.primaryLight,
        icon: Icons.task_alt_rounded,
        title: 'Manage Your Tasks',
        body:
            'Organise assignments, exams and projects in one place. Smart prioritisation keeps you focused on what matters most.'),
    _Slide(
        color: AppColors.success,
        light: AppColors.successLight,
        icon: Icons.notifications_active_rounded,
        title: 'Never Miss a Deadline',
        body:
            'Multi-layer reminders notify you 24 hours, 2 hours, and right at your deadline — automatically scheduled.'),
    _Slide(
        color: AppColors.accent,
        light: AppColors.accentLight,
        icon: Icons.insights_rounded,
        title: 'Track Your Progress',
        body:
            'Visualise your productivity with analytics, completion rates, streaks, and a Pomodoro focus timer.'),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: Duration.zero));
  }

  @override
  Widget build(BuildContext context) {
    final s = _slides[_page];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: Column(children: [
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)))),
        Expanded(
            child: PageView.builder(
          controller: _ctrl,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
        )),
        Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
            child: Column(children: [
              SmoothPageIndicator(
                  controller: _ctrl,
                  count: _slides.length,
                  effect: WormEffect(
                      activeDotColor: s.color,
                      dotColor: AppColors.divider,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 10)),
              const SizedBox(height: 28),
              SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                      onPressed: () => _page < _slides.length - 1
                          ? _ctrl.nextPage(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeInOutCubic)
                          : _finish(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: s.color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: Text(
                          _page < _slides.length - 1 ? 'Next →' : 'Get Started',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)))),
            ])),
      ])),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
                  width: 180,
                  height: 180,
                  decoration:
                      BoxDecoration(color: slide.light, shape: BoxShape.circle),
                  child: Icon(slide.icon, size: 86, color: slide.color))
              .animate(key: ValueKey(slide.title))
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 44),
          Text(slide.title,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center)
              .animate(key: ValueKey(slide.title + '1'))
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.25, curve: Curves.easeOut),
          const SizedBox(height: 14),
          Text(slide.body,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.65),
                  textAlign: TextAlign.center)
              .animate(key: ValueKey(slide.title + '2'))
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.25, curve: Curves.easeOut),
        ]),
      );
}

class _Slide {
  final Color color, light;
  final IconData icon;
  final String title, body;
  const _Slide(
      {required this.color,
      required this.light,
      required this.icon,
      required this.title,
      required this.body});
}
