import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../models/birthday_item.dart';

class BirthdayCelebrationSection extends StatefulWidget {
  final bool isHRView;
  const BirthdayCelebrationSection({super.key, this.isHRView = false});
  @override
  State<BirthdayCelebrationSection> createState() =>
      _BirthdayCelebrationSectionState();
}

class _BirthdayCelebrationSectionState extends State<BirthdayCelebrationSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<HRProvider>(context, listen: false)
          .fetchBirthdays(isStaff: !widget.isHRView);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HRProvider>();
    final todayBirthdays = provider.todayBirthdays;
    final upcomingBirthdays = provider.upcomingBirthdays;
    if (!provider.isBirthdaysLoading &&
        todayBirthdays.isEmpty &&
        upcomingBirthdays.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isBirthdaysLoading)
          _buildLoadingCard()
        else if (todayBirthdays.isNotEmpty) ...[
          _buildLabel("🎂 TODAY'S BIRTHDAYS", const Color(0xFFDB2777)),
          const SizedBox(height: 10),
          ...todayBirthdays.map((b) => _buildBirthdayCard(b)),
        ],
        if (upcomingBirthdays.isNotEmpty) ...[
          if (todayBirthdays.isNotEmpty) const SizedBox(height: 20),
          _buildLabel(
              '📅 UPCOMING BIRTHDAYS (Next 30 Days)', const Color(0xFF7C3AED)),
          const SizedBox(height: 10),
          _buildUpcomingList(upcomingBirthdays),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.1));

  Widget _buildLoadingCard() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.pink.shade50, Colors.purple.shade50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pink.shade100),
        ),
        child: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFDB2777))),
          const SizedBox(width: 12),
          Text('Loading birthday celebrations...',
              style: TextStyle(color: Colors.pink.shade700)),
        ]),
      );

  Widget _buildBirthdayCard(BirthdayItem b) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B9D), Color(0xFFAB5FCC), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFDB2777).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(children: [
          Positioned(
              top: 10,
              right: 30,
              child: _Dot(color: Colors.yellow.shade200, size: 10)),
          Positioned(
              top: 25,
              right: 80,
              child: _Dot(color: Colors.cyan.shade200, size: 7)),
          Positioned(
              bottom: 15,
              right: 50,
              child: _Dot(color: Colors.orange.shade200, size: 12)),
          Positioned(
              top: 12,
              right: 140,
              child: _Dot(color: Colors.white.withValues(alpha: 0.4), size: 6)),
          Padding(
            padding: const EdgeInsets.all(18),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                    child: Text(
                        b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Text('🎉', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              'Happy Birthday, ${b.name.split(' ').first}!',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                        '${b.designation.isNotEmpty ? b.designation : b.department} • ${b.department}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85)),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                          '🎂 ${b.birthdayFormatted} • Wishing you a wonderful day!',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ),
                  ])),
              const Column(children: [
                Text('🎈', style: TextStyle(fontSize: 28)),
                SizedBox(height: 4),
                Text('🎊', style: TextStyle(fontSize: 22)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildUpcomingList(List<BirthdayItem> upcoming) {
    final items = upcoming.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.shade100.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
          children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        final isLast = i == items.length - 1;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.indigo.shade400]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b.daysUntil.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(b.daysUntil == 1 ? 'day' : 'days',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 9)),
                    ]),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.purple.shade50,
                  child: Text(b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(b.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E1B4B))),
                    Text('${b.department} • ${b.birthdayFormatted}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ])),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('🎂', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ),
          if (!isLast)
            Divider(
                height: 1,
                color: Colors.purple.shade50,
                indent: 16,
                endIndent: 16),
        ]);
      }).toList()),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
