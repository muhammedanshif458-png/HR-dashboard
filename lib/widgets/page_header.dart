import 'package:flutter/material.dart';

/// Standardised page-level heading used across all HR screens.
///
/// Layout (always left-aligned):
///   EYEBROW LABEL  (12 px, spaced caps, muted)
///   Page Title     (22 px, weight 700)
///   Subtitle       (13 px, muted)
///
/// Optionally accepts [trailing] for action buttons on the right.
class PageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  /// Optional widget (e.g. a Row of buttons) placed on the trailing end.
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: eyebrow + title + subtitle ──────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17243A),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // ── Right: optional trailing actions ──────────────────────────
        if (trailing != null) ...[
          const SizedBox(width: 16),
          trailing!,
        ],
      ],
    );
  }
}
