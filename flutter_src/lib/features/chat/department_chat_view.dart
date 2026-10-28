import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../models/staff.dart';

class DepartmentChatView extends StatefulWidget {
  final String departmentKey;

  const DepartmentChatView({
    super.key,
    required this.departmentKey,
  });

  @override
  State<DepartmentChatView> createState() => _DepartmentChatViewState();
}

class _DepartmentChatViewState extends State<DepartmentChatView> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _isSending = false;

  static const Color _navy = Color(0xFF17243A);
  static const Color _sentBubble = Color(0xFF2457D6);
  static const Color _receivedBubble = Color(0xFFFFFFFF);
  static const Color _bgGray = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<HRProvider>();
      provider.markDepartmentChatAsRead(widget.departmentKey);
      await provider.loadDepartmentMessages(widget.departmentKey);
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  List<Staff> _getDepartmentStaff(HRProvider provider) {
    final isTech = widget.departmentKey.toLowerCase() == 'tech';
    final staffSource = provider.employeeDirectory.isNotEmpty
        ? provider.employeeDirectory
        : provider.staffList;
    return staffSource
        .where(
          (s) => s.department.toLowerCase().contains(
                isTech ? 'tech' : 'telecalling',
              ),
        )
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    try {
      await context
          .read<HRProvider>()
          .sendDepartmentMessage(widget.departmentKey, text);
      _scrollToBottom();
      _inputFocus.requestFocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send message. Retained in local room.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HRProvider>(
      builder: (context, hrProvider, _) {
        final thread = hrProvider.getDepartmentThread(widget.departmentKey);
        final isTech = widget.departmentKey.toLowerCase() == 'tech';
        final deptColor =
            isTech ? const Color(0xFF2457D6) : const Color(0xFFDB2777);
        final deptTitle =
            isTech ? 'Tech & Engineering' : 'Telecalling & Client Relations';
        final deptStaff = _getDepartmentStaff(hrProvider);

        final isWide = MediaQuery.of(context).size.width >= 960;
        final isInitialLoading = hrProvider.isDepartmentChatLoading &&
            !hrProvider.hasLoadedApiDepartmentChat;
        final hasError = hrProvider.departmentChatError != null &&
            !hrProvider.hasLoadedApiDepartmentChat;

        return Scaffold(
          backgroundColor: _bgGray,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(
                  context, hrProvider, deptTitle, deptColor, deptStaff.length),
              Expanded(
                child: isInitialLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF2457D6)),
                      )
                    : hasError
                        ? _buildErrorState(deptColor,
                            message: hrProvider.departmentChatError)
                        : Row(
                            children: [
                              // Main Department Group Chat Stream
                              Expanded(
                                flex: 3,
                                child: _buildGroupChatStream(context,
                                    hrProvider, thread, deptColor, deptTitle),
                              ),

                              // Right Sidebar: Authorized Department Members List
                              if (isWide) ...[
                                Container(width: 1, color: _border),
                                SizedBox(
                                  width: 320,
                                  child: _buildMembersRail(context, hrProvider,
                                      deptStaff, deptColor),
                                ),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── TOP HEADER WITH BACK TO DEPARTMENTS ─────────────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    HRProvider hrProvider,
    String deptTitle,
    Color deptColor,
    int memberCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Back button directly returns to Departments view
          IconButton(
            onPressed: () => hrProvider.navigateToDepartments(),
            icon:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFF475569)),
            tooltip: 'Return to Departments',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: deptColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.departmentKey.toLowerCase() == 'tech'
                  ? Icons.computer_rounded
                  : Icons.headset_mic_rounded,
              color: deptColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deptTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: deptColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Department Group',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: deptColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$memberCount Authorized Team Members • Live Group Conversation',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh Messages',
            onPressed: hrProvider.isDepartmentChatLoading
                ? null
                : () => hrProvider.loadDepartmentMessages(widget.departmentKey),
            icon: hrProvider.isDepartmentChatLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => hrProvider.navigateToEmployees(
              deptFilter: widget.departmentKey.toLowerCase() == 'tech'
                  ? 'Tech'
                  : 'Telecalling',
            ),
            icon: const Icon(Icons.people_outline, size: 15),
            label: const Text('View Department Staff'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── GROUP CHAT STREAM & INPUT ───────────────────────────────────────────
  Widget _buildGroupChatStream(
    BuildContext context,
    HRProvider hrProvider,
    DepartmentChatThread? thread,
    Color deptColor,
    String deptTitle,
  ) {
    final messages = thread?.messages ?? [];

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Informational Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: deptColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Department Group Conversation: All messages are visible to authorized $deptTitle employees.',
                    style: TextStyle(
                        fontSize: 11,
                        color: deptColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: Builder(
              builder: (ctx) {
                final callerId = hrProvider.currentUser?.id ?? '';
                // messages is already from outer Consumer — always current
                if (messages.isEmpty)
                  return _buildEmptyState(deptTitle, deptColor);
                final visible =
                    messages.where((m) => !m.isHiddenFor(callerId)).toList();
                if (visible.isEmpty)
                  return _buildEmptyState(deptTitle, deptColor);
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final msg = visible[i];
                    final isMe = msg.senderId == callerId;
                    final showDate = i == 0 ||
                        !_sameDay(visible[i - 1].timestamp, msg.timestamp);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _buildDateDivider(msg.timestamp),
                        _buildGroupMessageBubble(
                            msg, isMe, deptColor, callerId, hrProvider),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          _buildMessageInput(deptColor, deptTitle),
        ],
      ),
    );
  }

  Widget _buildGroupMessageBubble(
    ChatMessage msg,
    bool isMe,
    Color deptColor,
    String callerId,
    HRProvider hrProvider,
  ) {
    final timeStr = _formatTime(msg.timestamp);
    final canDeleteForEveryone = msg.senderId == callerId ||
        (hrProvider.currentUser?.role == 'HR Manager');

    Widget bubble = Container(
      constraints: const BoxConstraints(maxWidth: 540),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isMe ? _sentBubble : _receivedBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              isMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
        border: isMe ? null : Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            msg.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isMe ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.75)
                      : const Color(0xFF94A3B8),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Wrap with interaction detector (right-click on desktop, long-press on mobile)
    Widget interactive = GestureDetector(
      onLongPress: () => _showMessageOptions(
          context, msg, isMe, callerId, canDeleteForEveryone, hrProvider),
      onSecondaryTapUp: (details) => _showMessageOptionsAtPosition(
          context,
          details.globalPosition,
          msg,
          isMe,
          callerId,
          canDeleteForEveryone,
          hrProvider),
      child: bubble,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _avatar(msg.senderName.isNotEmpty ? msg.senderName : 'Staff',
                radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.senderName.isNotEmpty
                          ? msg.senderName
                          : 'Staff Member',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: deptColor,
                      ),
                    ),
                  ),
                interactive,
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Message Options (bottom sheet, triggered by long-press or right-click) ─

  void _showMessageOptions(
    BuildContext ctx,
    ChatMessage msg,
    bool isMe,
    String callerId,
    bool canDeleteForEveryone,
    HRProvider hrProvider,
  ) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_off_outlined,
                  color: Color(0xFF475569)),
              title: const Text('Delete for Me',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Hide this message only from your view.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(
                  ctx,
                  msg,
                  callerId,
                  hrProvider,
                  forEveryone: false,
                );
              },
            ),
            if (canDeleteForEveryone)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444)),
                title: const Text('Delete for Everyone',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444))),
                subtitle: const Text(
                    'Remove this message for all group members.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(
                    ctx,
                    msg,
                    callerId,
                    hrProvider,
                    forEveryone: true,
                  );
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
              title: const Text('Cancel',
                  style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Right-click on desktop shows a popup menu at cursor position
  void _showMessageOptionsAtPosition(
    BuildContext ctx,
    Offset position,
    ChatMessage msg,
    bool isMe,
    String callerId,
    bool canDeleteForEveryone,
    HRProvider hrProvider,
  ) async {
    final RenderBox overlay =
        Overlay.of(ctx).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        const PopupMenuItem(
          value: 'me',
          child: Row(
            children: [
              Icon(Icons.person_off_outlined,
                  size: 17, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('Delete for Me',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (canDeleteForEveryone)
          const PopupMenuItem(
            value: 'everyone',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    size: 17, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text('Delete for Everyone',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444))),
              ],
            ),
          ),
      ],
    );
    if (selected == null || !mounted) return;
    // ignore: use_build_context_synchronously
    _confirmDelete(
      context,
      msg,
      callerId,
      hrProvider,
      forEveryone: selected == 'everyone',
    );
  }

  // Confirmation dialog before deletion
  Future<void> _confirmDelete(
    BuildContext ctx,
    ChatMessage msg,
    String callerId,
    HRProvider hrProvider, {
    required bool forEveryone,
  }) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          forEveryone ? 'Delete for Everyone?' : 'Delete for Me?',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
        ),
        content: Text(
          forEveryone
              ? 'This message will be permanently removed for all group members.\n\nNote: Members who have already read the message may have seen its content.'
              : 'This message will be hidden from your view only. Other group members will continue to see it.',
          style: const TextStyle(
              fontSize: 13.5, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: forEveryone
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF2457D6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(forEveryone ? 'Delete for Everyone' : 'Delete for Me'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // ignore: use_build_context_synchronously
    _executeDelete(context, msg, callerId, hrProvider,
        forEveryone: forEveryone);
  }

  Future<void> _executeDelete(
    BuildContext ctx,
    ChatMessage msg,
    String callerId,
    HRProvider hrProvider, {
    required bool forEveryone,
  }) async {
    final result = forEveryone
        ? await hrProvider.deleteDepartmentMessageForEveryone(
            widget.departmentKey, msg.id, callerId)
        : await hrProvider.deleteDepartmentMessageForMe(
            widget.departmentKey, msg.id, callerId);

    if (!mounted) return;

    final snackColor = result.isSuccess
        ? const Color(0xFF10B981)
        : result.isPermissionDenied
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message, style: const TextStyle(fontSize: 13)),
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(
            seconds: result.isHardFailure || result.isPermissionDenied ? 5 : 3),
      ),
    );
  }

  Widget _buildMessageInput(Color deptColor, String deptTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              focusNode: _inputFocus,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Broadcast a message to $deptTitle group...',
                hintStyle:
                    const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: deptColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: deptColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── RIGHT SIDEBAR: AUTHORIZED DEPARTMENT MEMBERS ────────────────────────
  Widget _buildMembersRail(
    BuildContext context,
    HRProvider hrProvider,
    List<Staff> deptStaff,
    Color deptColor,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Icon(Icons.group_rounded, size: 18, color: deptColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Department Members (${deptStaff.length})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: deptStaff.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 64, color: _border),
              itemBuilder: (context, i) {
                final staff = deptStaff[i];
                final isLead = i == 0;
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: _avatar(staff.name, radius: 17),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LEAD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    staff.designation.isNotEmpty
                        ? staff.designation
                        : staff.role,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border)),
              color: Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group Access Restricted: Authorized active employees only.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String deptTitle, Color deptColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: deptColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, size: 48, color: deptColor),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages in $deptTitle yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Broadcast instructions or discuss projects with your team below.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color deptColor, {String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 44, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            message ?? 'Unable to connect to chat stream',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context
                .read<HRProvider>()
                .loadDepartmentMessages(widget.departmentKey),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: deptColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final now = DateTime.now();
    String text;
    if (_sameDay(dt, now)) {
      text = 'Today';
    } else if (_sameDay(dt, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: _border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: _border)),
        ],
      ),
    );
  }

  Widget _avatar(String name, {double radius = 18}) {
    final initials = _initials(name);
    final color = _avatarColor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF2457D6),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    if (name.isEmpty) return palette[0];
    return palette[name.codeUnitAt(0) % palette.length];
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
