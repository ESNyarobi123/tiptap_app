import 'package:flutter/material.dart';

/// Animated counter that counts up from 0 to [end]
/// Perfect for stats, tips totals, order counts, etc.
class AnimatedCounter extends StatefulWidget {
  final num end;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextStyle? style;
  final int decimals;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.decimals = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _oldEnd = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.end.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _oldEnd = widget.end;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = Tween<double>(
        begin: _oldEnd.toDouble(),
        end: widget.end.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _oldEnd = widget.end;
      _controller
        ..reset()
        ..forward();
    }
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
        final value = _animation.value;
        String text;
        if (widget.decimals > 0) {
          text = value.toStringAsFixed(widget.decimals);
        } else {
          text = value.toInt().toString();
        }
        return Text(
          '${widget.prefix}$text${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Animated counter with formatted numbers (e.g. 1,350,000)
class AnimatedFormattedCounter extends StatefulWidget {
  final num end;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextStyle? style;
  final String Function(num value)? formatter;
  final Curve curve;

  const AnimatedFormattedCounter({
    super.key,
    required this.end,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.style,
    this.formatter,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedFormattedCounter> createState() =>
      _AnimatedFormattedCounterState();
}

class _AnimatedFormattedCounterState extends State<AnimatedFormattedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _oldEnd = 0;

  String _defaultFormat(num v) {
    if (v >= 1000) {
      // Simple comma formatting
      final s = v.toInt().toString();
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
        buffer.write(s[i]);
      }
      return buffer.toString();
    }
    return v.toInt().toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.end.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _oldEnd = widget.end;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedFormattedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = Tween<double>(
        begin: _oldEnd.toDouble(),
        end: widget.end.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _oldEnd = widget.end;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.formatter ?? _defaultFormat;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${fmt(_animation.value)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
