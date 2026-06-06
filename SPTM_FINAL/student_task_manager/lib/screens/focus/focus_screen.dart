import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  static const _focusMins = 25, _shortMins = 5, _longMins = 15;

  late int _total, _remaining;
  bool _running = false;
  int  _sessions = 0;
  String _mode = 'Focus';
  Timer? _timer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _total = _remaining = _focusMins * 60;
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() { _timer?.cancel(); _pulse.dispose(); super.dispose(); }

  void _startStop() {
    if (_running) { _timer?.cancel(); setState(() => _running = false); return; }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) { _complete(); } else { setState(() => _remaining--); }
    });
    setState(() => _running = true);
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _running = false;
      if (_mode == 'Focus') {
        _sessions++;
        _mode  = _sessions % 4 == 0 ? 'Long Break' : 'Short Break';
        _total = _remaining = (_sessions % 4 == 0 ? _longMins : _shortMins) * 60;
      } else {
        _mode = 'Focus'; _total = _remaining = _focusMins * 60;
      }
    });
  }

  void _reset() { _timer?.cancel(); setState(() { _running = false; _remaining = _total; }); }

  void _setMode(String m) {
    _timer?.cancel();
    setState(() {
      _mode = m; _running = false;
      _total = _remaining = (m == 'Focus' ? _focusMins : m == 'Short Break' ? _shortMins : _longMins) * 60;
    });
  }

  String get _timeStr {
    final m = _remaining ~/ 60, s = _remaining % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  double get _progress => 1 - (_remaining / _total);

  Color get _color => _mode == 'Focus' ? AppColors.primary
      : _mode == 'Short Break' ? AppColors.success : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Focus Mode')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        // Mode selector
        Container(padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(children: ['Focus', 'Short Break', 'Long Break'].map((m) {
            final sel = _mode == m;
            return Expanded(child: GestureDetector(onTap: () => _setMode(m),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: sel ? _color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(m, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.textSecondary)))));
          }).toList())),
        const SizedBox(height: 40),

        // Timer
        AnimatedBuilder(animation: _pulse, builder: (_, child) =>
            Transform.scale(scale: _running ? 1.0 + _pulse.value * 0.02 : 1.0, child: child),
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 240, height: 240,
              child: CircularProgressIndicator(value: _progress, strokeWidth: 8,
                  backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(_color))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_timeStr, style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold,
                  color: _color, letterSpacing: 2)),
              Text(_mode, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
          ])),
        const SizedBox(height: 40),

        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CtrlBtn(Icons.refresh_rounded, _reset),
          const SizedBox(width: 20),
          GestureDetector(onTap: _startStop,
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              width: 80, height: 80,
              decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36))),
          const SizedBox(width: 20),
          _CtrlBtn(Icons.skip_next_rounded, _complete),
        ]),
        const SizedBox(height: 40),

        // Session dots
        Container(width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text('Sessions Completed', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(duration: const Duration(milliseconds: 300),
                  width: i < _sessions ? 20 : 16, height: i < _sessions ? 20 : 16,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: i < _sessions ? (i % 4 == 3 ? AppColors.warning : AppColors.primary) : AppColors.divider))))),
            const SizedBox(height: 12),
            Text('$_sessions sessions · ${_sessions * 25} min focused',
                style: Theme.of(context).textTheme.bodyMedium),
          ])),
        const SizedBox(height: 20),

        Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 20), const SizedBox(width: 12),
            Expanded(child: Text(
              _mode == 'Focus' ? 'Stay focused! Close distracting apps and put your phone on silent.'
                  : 'Take a proper break — stretch, hydrate, and rest your eyes.',
              style: const TextStyle(fontSize: 13, color: AppColors.primary))),
          ])),
      ])),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CtrlBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 54, height: 54,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Icon(icon, color: AppColors.textSecondary)));
}
