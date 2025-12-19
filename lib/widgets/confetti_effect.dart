import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Confetti efekt při dokončení návyku
class ConfettiEffect extends StatefulWidget {
  final VoidCallback onComplete;
  final Color color;
  
  const ConfettiEffect({
    super.key,
    required this.onComplete,
    this.color = Colors.orange,
  });
  
  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _particleCount = 30;
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _particleCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: (1500 + _random.nextInt(500)).toInt()),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();
    
    // Spustit všechny animace
    for (var controller in _controllers) {
      controller.forward();
    }
    
    // Zavolat onComplete po dokončení
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(_particleCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final progress = _animations[index].value;
            final angle = _random.nextDouble() * 2 * math.pi;
            final distance = 200.0 * progress;
            final x = math.cos(angle) * distance;
            final y = math.sin(angle) * distance + 100 * progress;
            final rotation = progress * 2 * math.pi;
            final size = 8.0 + _random.nextDouble() * 8.0;
            final opacity = 1.0 - progress;
            
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + x - size / 2,
              top: MediaQuery.of(context).size.height / 2 + y - size / 2,
              child: Transform.rotate(
                angle: rotation,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: _getRandomColor(),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
  
  Color _getRandomColor() {
    final colors = [
      widget.color,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];
    return colors[_random.nextInt(colors.length)];
  }
}

