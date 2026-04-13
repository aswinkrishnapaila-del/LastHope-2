import 'package:flutter/material.dart';

/// A high-fidelity, single-click SOS button with a pulsing ring animation.
/// Pass [isDispatching] = true to show the "DISPATCHING..." loading state.
class SosButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDispatching;

  const SosButton({
    super.key,
    required this.onTap,
    this.isDispatching = false,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  // Pulsing ring: expands outward and fades
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // Subtle button press scale
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  static const _buttonSize = 180.0;
  static const _buttonColor = Color(0xFFB71C1C); // deep red 900

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.08,
    );

    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDispatching
          ? null
          : (_) => _tapController.forward(),
      onTapUp: widget.isDispatching
          ? null
          : (_) {
              _tapController.reverse();
              widget.onTap();
            },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _tapController]),
        builder: (context, _) {
          return SizedBox(
            width: _buttonSize * 1.6,
            height: _buttonSize * 1.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Pulsing ring ──
                if (!widget.isDispatching)
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        width: _buttonSize,
                        height: _buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _buttonColor,
                        ),
                      ),
                    ),
                  ),

                // ── Main button ──
                Transform.scale(
                  scale: _tapScale.value,
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDispatching
                          ? Colors.red.shade900.withValues(alpha: 0.7)
                          : _buttonColor,
                      boxShadow: [
                        BoxShadow(
                          color: _buttonColor.withValues(alpha: 0.6),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: widget.isDispatching
                        ? _buildDispatchingContent()
                        : _buildIdleContent(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning_rounded,
          color: Colors.white,
          size: 38,
        ),
        const SizedBox(height: 6),
        Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'TAP FOR HELP',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'DISPATCHING...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
