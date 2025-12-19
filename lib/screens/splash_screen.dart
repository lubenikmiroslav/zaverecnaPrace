import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_gradient_background.dart';

/// Moderní splash screen s animacemi
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({
    super.key,
    required this.onComplete,
  });
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Logo animation (bounce in)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _logoController.forward();
    _progressController.forward().then((_) {
      // Wait a bit before completing
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                
                // Logo with bounce animation
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.white,
                                    AppColors.whiteWithOpacity(0.9),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryOrange.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppGradients.primaryGradient,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // App name
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _logoAnimation.value)),
                        child: Text(
                          'HabitTrack',
                          style: AppTextStyles.logoText.copyWith(
                            fontSize: 36,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _logoAnimation.value)),
                        child: Text(
                          'Sleduj své návyky, zlepšuj svůj život',
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    
                    // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              minHeight: 6,
                              backgroundColor: AppColors.whiteWithOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _progressAnimation.value,
                            child: Text(
                              'Načítání...',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

