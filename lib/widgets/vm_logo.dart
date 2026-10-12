import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logo officiel Visual Media (VM).
/// Monogramme "VM" + cône de lecture, sans asset externe.
class VMLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  const VMLogo({super.key, this.size = 44, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: VMTheme.logoGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: VMTheme.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _VMMarkPainter(),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Visual Media',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: VMTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'VM PLAYER • v1.0',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: VMTheme.textSecondary.withValues(alpha: 0.9),
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VMMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final playPaint = Paint()..color = Colors.white;
    // Triangle "play" stylisé façon cône VLC modernisé.
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.34, h * 0.26)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.34, h * 0.74)
      ..close();
    canvas.drawPath(path, playPaint);

    // Barre du "M" en bas.
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.22, h * 0.80),
      Offset(w * 0.78, h * 0.80),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
