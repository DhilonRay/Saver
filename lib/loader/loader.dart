import 'package:flutter/material.dart';
import '../widgets/draw_dot.dart';

class Loader extends StatefulWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  _LoaderState createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HorizontalRotatingDots(
              size: 60,
              colors: [Colors.blue.shade600, Colors.orange.shade600, Colors.purple.shade600],
            ),
           
          
          ],
        ),
      ),
    );
  }
}

class HorizontalRotatingDots extends StatefulWidget {
  final double size;
  final List<Color> colors;

  const HorizontalRotatingDots({
    Key? key,
    required this.size,
    this.colors = const [Colors.blue, Colors.orange, Colors.purple],
  }) : super(key: key);

  @override
  _HorizontalRotatingDotsState createState() => _HorizontalRotatingDotsState();
}

class _HorizontalRotatingDotsState extends State<HorizontalRotatingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _leftDotTranslate;

  late Animation<double> _middleDotScale;
  late Animation<Offset> _middleDotTranslate;

  late Animation<double> _rightDotScale;
  late Animation<Offset> _rightDotTranslate;

  final Interval _interval = const Interval(
    0.0,
    1.0,
    curve: Curves.easeOutCubic,
  );
  @override
  void initState() {
    super.initState();
    final double size = widget.size;
    final double dotSize = size / 4;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _leftDotTranslate = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(size - dotSize, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _interval,
      ),
    );

    _middleDotScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _interval,
      ),
    );

    _middleDotTranslate = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-(size - dotSize) / 2, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _interval,
      ),
    );

    _rightDotScale = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _interval,
      ),
    );

    _rightDotTranslate = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-(size - dotSize) / 2, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _interval,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final List<Color> colors = widget.colors;
    final double dotSize = size / 3.5;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Transform.translate(
              offset: _leftDotTranslate.value,
              child: DrawDot.circular(
                dotSize: dotSize,
                color: colors[0],
              ),
            ),
            Transform.scale(
              scale: _middleDotScale.value,
              child: Transform.translate(
                offset: _middleDotTranslate.value,
                child: DrawDot.circular(
                  dotSize: dotSize,
                  color: colors[1],
                ),
              ),
            ),
            Transform.translate(
              offset: _rightDotTranslate.value,
              child: Transform.scale(
                scale: _rightDotScale.value,
                child: DrawDot.circular(
                  dotSize: dotSize,
                  color: colors[2],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}