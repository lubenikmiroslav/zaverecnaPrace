import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Animované gradient pozadí
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors = const [],
  });
  
  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = widget.colors.isEmpty
        ? [
            AppColors.primaryOrange,
            AppColors.primaryPink,
            AppColors.primaryPurple,
          ]
        : widget.colors;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + _animation.value * 0.5,
                -1.0 + _animation.value * 0.5,
              ),
              end: Alignment(
                1.0 - _animation.value * 0.5,
                1.0 - _animation.value * 0.5,
              ),
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

