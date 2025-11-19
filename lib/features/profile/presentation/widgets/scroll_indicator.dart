import 'package:flutter/material.dart';

class AnimatedScrollIndicator extends StatefulWidget {
  const AnimatedScrollIndicator({super.key});

  @override
  State<AnimatedScrollIndicator> createState() => _AnimatedScrollIndicatorState();
}

class _AnimatedScrollIndicatorState extends State<AnimatedScrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.black,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '올려서 나의 음주 기록 확인해보기',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
