import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/birthday_item.dart';
import '../providers/hr_provider.dart';

class BirthdayCelebrationSection extends StatefulWidget {
  final bool isHRView;

  const BirthdayCelebrationSection({super.key, this.isHRView = false});

  @override
  State<BirthdayCelebrationSection> createState() =>
      _BirthdayCelebrationSectionState();
}

class _BirthdayCelebrationSectionState extends State<BirthdayCelebrationSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _midnightRefreshTimer;
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HRProvider>().fetchBirthdays(isStaff: !widget.isHRView);
        _scheduleCompanyMidnightRefresh();
      }
    });
  }

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _scheduleCompanyMidnightRefresh() {
    final indiaNow =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final nextMidnight =
        DateTime(indiaNow.year, indiaNow.month, indiaNow.day + 1);
    _midnightRefreshTimer = Timer(nextMidnight.difference(indiaNow), () {
      if (!mounted) return;
      context
          .read<HRProvider>()
          .fetchBirthdays(isStaff: !widget.isHRView, forceRefresh: true);
      _scheduleCompanyMidnightRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRProvider>();
    final birthdays = provider.todayBirthdays
        .where((birthday) => !_dismissed.contains(_keyFor(birthday)))
        .toList();

    if (provider.isBirthdaysLoading && provider.todayBirthdays.isEmpty) {
      return _statusCard(
        child: const Row(children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFDB2777)),
          ),
          SizedBox(width: 12),
          Text('Loading birthday celebrations...'),
        ]),
      );
    }
    if (provider.birthdaysError != null && provider.todayBirthdays.isEmpty) {
      return _statusCard(
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Could not load today’s birthdays.')),
          TextButton(
            onPressed: provider.isBirthdaysLoading
                ? null
                : () => provider.fetchBirthdays(isStaff: !widget.isHRView),
            child: const Text('Retry'),
          ),
        ]),
      );
    }
    if (birthdays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('🎂 TODAY’S BIRTHDAYS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDB2777),
                  letterSpacing: 1.1)),
        ),
        ...birthdays.map((birthday) => _birthdayCard(birthday)),
      ],
    );
  }

  Widget _birthdayCard(BirthdayItem birthday) {
    final initials = birthday.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: 0.994 + (_animationController.value * 0.006),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF1F5), Color(0xFFF5F3FF)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFBCFE8)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFDB2777),
            child: birthday.profileImage?.trim().isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      birthday.profileImage!.trim(),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _initials(initials),
                    ),
                  )
                : _initials(initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉 Happy Birthday, ${birthday.name}!',
                    style: const TextStyle(
                        color: Color(0xFF831843),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 5),
                const Text(
                    'Wishing you happiness, success and a wonderful year ahead!',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                const SizedBox(height: 4),
                const Text('— Team LY SOFTWARE ❤️',
                    style: TextStyle(
                        color: Color(0xFF9D174D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss birthday notification',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _dismissed.add(_keyFor(birthday))),
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF9F1239),
          ),
        ]),
      ),
    );
  }

  Widget _statusCard({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFBCFE8)),
        ),
        child: child,
      );

  Widget _initials(String initials) => Center(
        child: Text(initials.isEmpty ? '?' : initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      );

  String _keyFor(BirthdayItem birthday) => birthday.employeeId.isNotEmpty
      ? birthday.employeeId
      : birthday.id.isNotEmpty
          ? birthday.id
          : birthday.name;
}
