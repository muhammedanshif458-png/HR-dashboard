import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final String? displayValue;
  final IconData icon;
  final String tone;
  final bool isActive;
  final VoidCallback onClick;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.displayValue,
    required this.icon,
    required this.tone,
    required this.isActive,
    required this.onClick,
  });

  Color _getToneColor() {
    switch (tone) {
      case 'green':
        return const Color(0xFF10B981);
      case 'amber':
        return const Color(0xFFF59E0B);
      case 'blue':
        return const Color(0xFF2457D6);
      case 'red':
        return const Color(0xFFEF4444);
      case 'slate':
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toneColor = _getToneColor();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onClick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? toneColor.withValues(alpha: 0.08) : Colors.white,
            border: Border.all(
              color: isActive ? toneColor : const Color(0xFFE2E8F0),
              width: isActive ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (!isActive)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: toneColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: toneColor, size: 20),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: toneColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'FILTERED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: toneColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayValue ?? value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
