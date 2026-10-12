import 'package:flutter/material.dart';


class MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final String tone;
  final bool isActive;
  final VoidCallback onClick;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.isActive,
    required this.onClick,
  });

  Color _getToneColor() {
    switch (tone) {
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'slate':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final toneColor = _getToneColor();
    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? toneColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isActive ? toneColor : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: toneColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: toneColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
