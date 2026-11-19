import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  static const Color _navy = Color(0xFF1E3A5F);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFFEFF6FF);
  static const Color _bgGray = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();

    return Scaffold(
      backgroundColor: _bgGray,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), _blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct Messaging (1-on-1)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'LY SOFTWARE • Internal Communications',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => hrProvider.navigateToDepartmentChat('tech'),
                  icon: const Icon(Icons.forum_outlined, size: 16),
                  label: const Text('Open Department Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Unsupported Feature Information
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _border),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: _lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_chat_unread_outlined,
                              size: 48,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '1-on-1 Direct Messaging Unsupported',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Individual direct messages are currently not supported by the backend REST API contract. '
                            'To prevent presenting fabricated conversations, sample chat threads have been removed.\n\n'
                            'Team members communicate through live Department Group Chat for Tech & Engineering and '
                            'Telecalling & Client Relations.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'API Specifications Required:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• GET /api/chat/threads - List user conversations\n'
                                  '• POST /api/chat/messages - Dispatch 1-on-1 message\n'
                                  '• PATCH /api/chat/messages/:id/read - Mark thread read',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    hrProvider.setScreen('hr-dashboard'),
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Back to Dashboard'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    hrProvider.navigateToDepartmentChat('tech'),
                                icon: const Icon(Icons.forum, size: 16),
                                label: const Text('Go to Department Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
