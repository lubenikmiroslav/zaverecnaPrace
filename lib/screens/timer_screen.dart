import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TimerScreen extends StatefulWidget {
  final Map<String, dynamic> habit;
  
  const TimerScreen({super.key, required this.habit});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.habit['timer_duration'] ?? 0;
    _secondsRemaining = duration * 60; // převod na sekundy
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_secondsRemaining > 0) {
      setState(() {
        _isRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _isCompleted = true;
          });
          _showCompletionDialog();
        }
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    final duration = widget.habit['timer_duration'] ?? 0;
    setState(() {
      _secondsRemaining = duration * 60;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Čas vypršel!'),
        content: Text('Gratulujeme! Dokončil jsi "${widget.habit['name']}"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Zavřít dialog
              Navigator.pop(context); // Zavřít timer screen
            },
            child: const Text('Skvělé!'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    final total = (widget.habit['timer_duration'] ?? 0) * 60;
    if (total == 0) return 0;
    return 1 - (_secondsRemaining / total);
  }

  @override
  Widget build(BuildContext context) {
    final iconCode = int.tryParse(widget.habit['icon'] ?? '') ?? Icons.check.codePoint;
    final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
    final colorStr = widget.habit['color'].toString().replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorStr'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit['name']),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikona návyku
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 4,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 60,
                ),
              ),
              const SizedBox(height: 40),

              // Časovač
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 40),

              // Progress bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _getProgress(),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Tlačítka
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning && _secondsRemaining > 0)
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  if (_isRunning) ...[
                    ElevatedButton.icon(
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pauza'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

