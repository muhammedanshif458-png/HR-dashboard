import 'package:flutter/cupertino.dart';
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
  final TextEditingController _memberFilterCtrl = TextEditingController();

  bool _isSending = false;
  bool _showBanner = true;
  String _memberFilter = '';
  final List<String> _recentEmojis = [];
  String? _lastNewestMessageId;
  HRProvider? _observedProvider;

  static const Map<String, List<String>> _emojiCategories = {
    'Smileys & People': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😅',
      '😂',
      '🙂',
      '😉',
      '😊',
      '😍',
      '🥰',
      '😎',
      '🤔',
      '😭',
      '🙏',
      '👏',
      '👍',
      '👋',
      '❤️',
      '✨'
    ],
    'Animals & Nature': [
      '🐶',
      '🐱',
      '🐻',
      '🦊',
      '🐼',
      '🐸',
      '🦁',
      '🐯',
      '🌸',
      '🌻',
      '🌈',
      '🌳',
      '🍀',
      '🌿'
    ],
    'Food & Drink': [
      '🍎',
      '🍕',
      '🍔',
      '🍟',
      '🍰',
      '☕',
      '🍵',
      '🥗',
      '🍇',
      '🍩',
      '🎂'
    ],
    'Activities': ['⚽', '🏀', '🎮', '🎉', '🎵', '🎯', '🏆', '🎨'],
    'Travel & Places': ['🚗', '✈️', '🚀', '🏖️', '🏙️', '🏠', '🗺️'],
    'Objects': ['💡', '📱', '💻', '📚', '📌', '📝', '🎁', '🔔'],
    'Symbols': ['✅', '❌', '⭐', '🔥', '💯', '➕', '❗', '💬'],
    'Flags': ['🇮🇳', '🇺🇸', '🇬🇧', '🇯🇵', '🇦🇺', '🇨🇦'],
  };

  static const Map<String, String> _emojiNames = {
    'smile': '😀',
    'grin': '😁',
    'laugh': '😂',
    'wink': '😉',
    'love': '❤️',
    'heart': '❤️',
    'hug': '🤗',
    'pray': '🙏',
    'clap': '👏',
    'thumbs up': '👍',
    'wave': '👋',
    'dog': '🐶',
    'cat': '🐱',
    'bear': '🐻',
    'fox': '🦊',
    'flower': '🌸',
    'sunflower': '🌻',
    'rainbow': '🌈',
    'tree': '🌳',
    'apple': '🍎',
    'pizza': '🍕',
    'burger': '🍔',
    'coffee': '☕',
    'cake': '🍰',
    'football': '⚽',
    'basketball': '🏀',
    'game': '🎮',
    'party': '🎉',
    'music': '🎵',
    'car': '🚗',
    'plane': '✈️',
    'rocket': '🚀',
    'beach': '🏖️',
    'home': '🏠',
    'light': '💡',
    'phone': '📱',
    'computer': '💻',
    'book': '📚',
    'gift': '🎁',
    'bell': '🔔',
    'check': '✅',
    'star': '⭐',
    'fire': '🔥',
    'india': '🇮🇳',
  };

  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _memberFilterCtrl.addListener(() {
      setState(() {
        _memberFilter = _memberFilterCtrl.text.trim().toLowerCase();
      });
    });
    _initChat();
  }

  @override
  void didUpdateWidget(DepartmentChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departmentKey != widget.departmentKey) {
      _initChat();
    }
  }

  void _initChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<HRProvider>();
      _observedProvider?.removeListener(_onProviderUpdate);
      _observedProvider = provider;
      provider.addListener(_onProviderUpdate);
      provider.markDepartmentChatAsRead(widget.departmentKey);
      provider.initDepartmentChatSocket(widget.departmentKey);
      await provider.loadDepartmentMessages(widget.departmentKey);
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  void _onProviderUpdate() {
    if (!mounted || _observedProvider == null) return;
    final messages = _observedProvider!
            .getDepartmentThread(widget.departmentKey)
            ?.messages ??
        const <ChatMessage>[];
    final newestId = messages.isEmpty ? null : messages.last.id;
    if (_lastNewestMessageId != null &&
        newestId != null &&
        newestId != _lastNewestMessageId) {
      _scrollToBottom();
    }
    _lastNewestMessageId = newestId;
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
    final hrProvider = context.read<HRProvider>();
    if (text.isEmpty || _isSending || hrProvider.isSendingDepartmentMessage) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await hrProvider.sendDepartmentMessage(widget.departmentKey, text);
      _msgCtrl.clear();
      _scrollToBottom();
      _inputFocus.requestFocus();
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send message: $errText'),
            backgroundColor: const Color(0xFFDC2626),
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

  void _insertEmoji(String emoji) {
    final value = _msgCtrl.value;
    final start =
        value.selection.isValid ? value.selection.start : value.text.length;
    final end = value.selection.isValid ? value.selection.end : start;
    final updated = value.text.replaceRange(start, end, emoji);
    _msgCtrl.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    _recentEmojis.remove(emoji);
    _recentEmojis.insert(0, emoji);
    if (_recentEmojis.length > 16) _recentEmojis.removeLast();
    _inputFocus.requestFocus();
  }

  Future<void> _openEmojiPicker() async {
    final search = TextEditingController();
    String selectedCategory = _emojiCategories.keys.first;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) {
          final query = search.text.trim().toLowerCase();
          final results = <String>{};
          if (query.isNotEmpty) {
            for (final entry in _emojiNames.entries) {
              if (entry.key.contains(query)) results.add(entry.value);
            }
            for (final entry in _emojiCategories.entries) {
              if (entry.key.toLowerCase().contains(query)) {
                results.addAll(entry.value);
              }
            }
            for (final emoji
                in _emojiCategories.values.expand((items) => items)) {
              if (emoji.contains(query)) results.add(emoji);
            }
          }
          final emojis = query.isNotEmpty
              ? results.toList()
              : selectedCategory == 'Recently used'
                  ? _recentEmojis
                  : _emojiCategories[selectedCategory]!;
          return SafeArea(
            child: SizedBox(
              height: 430,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: search,
                      onChanged: (_) => refresh(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search emoji',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_recentEmojis.isNotEmpty)
                            _emojiCategoryChip(
                                'Recently used',
                                selectedCategory,
                                (v) => refresh(() => selectedCategory = v)),
                          for (final category in _emojiCategories.keys)
                            _emojiCategoryChip(category, selectedCategory,
                                (v) => refresh(() => selectedCategory = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 8,
                        children: [
                          for (final emoji in emojis)
                            InkWell(
                              onTap: () {
                                _insertEmoji(emoji);
                                Navigator.pop(sheetContext);
                              },
                              child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 27))),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    search.dispose();
  }

  Widget _emojiCategoryChip(
    String category,
    String selected,
    ValueChanged<String> onSelected,
  ) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(category),
          selected: category == selected,
          onSelected: (_) => onSelected(category),
        ),
      );

  @override
  void dispose() {
    _observedProvider?.removeListener(_onProviderUpdate);
    try {
      context.read<HRProvider>().leaveDepartmentChatSocket();
    } catch (_) {}
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    _memberFilterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HRProvider>(
      builder: (context, hrProvider, _) {
        final thread = hrProvider.getDepartmentThread(widget.departmentKey);
        final isTech = widget.departmentKey.toLowerCase() == 'tech';
        final deptColor =
            isTech ? const Color(0xFF2563EB) : const Color(0xFFDB2777);
        final deptTitle =
            isTech ? 'Tech & Engineering' : 'Telecalling & Client Relations';
        final deptStaff = _getDepartmentStaff(hrProvider);

        final isWide = MediaQuery.of(context).size.width >= 960;
        final isInitialLoading = hrProvider.isDepartmentChatLoading &&
            !hrProvider.hasLoadedApiDepartmentChat;
        final hasError = hrProvider.departmentChatError != null &&
            !hrProvider.hasLoadedApiDepartmentChat;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24.0 : 12.0,
              vertical: isWide ? 20.0 : 12.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // 1. Top Header
                  _buildTopHeader(context, hrProvider, deptTitle, deptColor,
                      deptStaff.length, isTech),

                  // 2. Access Restricted Info Banner
                  if (_showBanner) _buildBanner(deptTitle),

                  // 3. Body: Chat Stream & Right Member Rail
                  Expanded(
                    child: isInitialLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0F172A),
                              strokeWidth: 2.5,
                            ),
                          )
                        : hasError
                            ? _buildErrorState(deptColor,
                                message: hrProvider.departmentChatError)
                            : Row(
                                children: [
                                  // Left / Main Chat Stream
                                  Expanded(
                                    child: _buildGroupChatStream(
                                      context,
                                      hrProvider,
                                      thread,
                                      deptColor,
                                      deptTitle,
                                    ),
                                  ),

                                  // Right Rail: Authorized Department Members
                                  if (isWide) ...[
                                    Container(width: 1, color: _border),
                                    SizedBox(
                                      width: 320,
                                      child: _buildMembersRail(
                                        context,
                                        hrProvider,
                                        deptStaff,
                                        deptColor,
                                        deptTitle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                  ),
                ],
              ),
            ),
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
    bool isTech,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Back button directly returns to Departments view
          IconButton(
            onPressed: () => hrProvider.navigateToDepartments(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
            tooltip: 'Return to Departments',
          ),
          const SizedBox(width: 8),

          // Department Avatar / Icon Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Icon(
              isTech ? Icons.laptop_mac_rounded : Icons.headset_mic_rounded,
              color: const Color(0xFF334155),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Department Title & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deptTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Text(
                        'Department Group',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      key: const ValueKey('chat_live_status_badge'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hrProvider.isChatSocketConnected
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hrProvider.isChatSocketConnected
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hrProvider.isChatSocketConnected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hrProvider.isChatSocketConnected
                                ? '• Live Sync'
                                : 'Connecting...',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hrProvider.isChatSocketConnected
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$memberCount Authorized Team Members • Live Group Conversation',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Search Button
          InkWell(
            onTap: () =>
                _showDepartmentMessageSearch(context, hrProvider, deptColor),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          InkWell(
            onTap: hrProvider.isDepartmentChatLoading
                ? null
                : () => hrProvider.loadDepartmentMessages(widget.departmentKey),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: hrProvider.isDepartmentChatLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // More Options Menu
          PopupMenuButton<String>(
            key: const ValueKey('department_chat_more_menu'),
            tooltip: 'Chat options',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _border),
            ),
            onSelected: (action) {
              if (action == 'search') {
                _showDepartmentMessageSearch(context, hrProvider, deptColor);
              } else if (action == 'clear') {
                _confirmClearDepartmentChat(context, hrProvider);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 16, color: Color(0xFF475569)),
                    SizedBox(width: 8),
                    Text(
                      'Search messages',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: !hrProvider.isDepartmentChatClearing,
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services_outlined,
                        size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Text(
                      hrProvider.isDepartmentChatClearing
                          ? 'Clearing chat…'
                          : 'Clear chat',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // View Department Staff Outlined Button
          OutlinedButton.icon(
            onPressed: () => hrProvider.navigateToEmployees(
              deptFilter: widget.departmentKey.toLowerCase() == 'tech'
                  ? 'Tech'
                  : 'Telecalling',
            ),
            icon: const Icon(Icons.people_outline_rounded, size: 16),
            label: const Text('View Department Staff'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCESS RESTRICTED ALERT BANNER ──────────────────────────────────────
  Widget _buildBanner(String deptTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: Color(0xFFDBEAFE))),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline_rounded,
              size: 13, color: Color(0xFF1E40AF)),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF334155),
                ),
                children: [
                  const TextSpan(
                    text: 'Group Access Restricted: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  TextSpan(
                    text:
                        'Department Group Conversation: All messages are visible to authorized $deptTitle employees.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showBanner = false),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child:
                  Icon(Icons.close_rounded, size: 15, color: Color(0xFF64748B)),
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
      color: Colors.white,
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: Builder(
              builder: (ctx) {
                final callerId = hrProvider.departmentChatUserId;
                if (messages.isEmpty) {
                  return _buildEmptyState(deptTitle, deptColor);
                }
                final visible = messages
                    .where((m) => !m.deletedByIds.contains(callerId))
                    .toList();
                if (visible.isEmpty) {
                  return _buildEmptyState(deptTitle, deptColor);
                }

                final hasMore = hrProvider.departmentChatHasMore;
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: visible.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (hasMore && i == 0) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextButton.icon(
                            key: const ValueKey('chat_load_older_button'),
                            onPressed: hrProvider.isDepartmentChatLoadingMore
                                ? null
                                : () => hrProvider.loadDepartmentMessages(
                                      widget.departmentKey,
                                      isLoadMore: true,
                                    ),
                            icon: hrProvider.isDepartmentChatLoadingMore
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  )
                                : const Icon(Icons.history_rounded, size: 16),
                            label: Text(
                              hrProvider.isDepartmentChatLoadingMore
                                  ? 'Loading older messages...'
                                  : 'Load earlier messages (${hrProvider.departmentChatTotalMessages - visible.length} remaining)',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final msgIndex = hasMore ? i - 1 : i;
                    final msg = visible[msgIndex];
                    final isMe = msg.senderId == callerId;
                    final showDate = msgIndex == 0 ||
                        !_sameDay(
                            visible[msgIndex - 1].timestamp, msg.timestamp);
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
          _buildMessageInput(hrProvider, deptColor, deptTitle),
        ],
      ),
    );
  }

  // ── MESSAGE BUBBLE MATCHING SCREENSHOT DESIGN ───────────────────────────
  Widget _buildGroupMessageBubble(
    ChatMessage msg,
    bool isMe,
    Color deptColor,
    String callerId,
    HRProvider hrProvider,
  ) {
    final timeStr = _formatTime(msg.timestamp);
    final canDeleteForEveryone = !msg.deletedForEveryone &&
        callerId.isNotEmpty &&
        msg.senderId == callerId;

    final senderName = isMe
        ? (msg.senderName.isNotEmpty && msg.senderName != 'Super Admin'
            ? msg.senderName
            : 'Admin')
        : (msg.senderName.isNotEmpty && msg.senderName != 'Super Admin'
            ? msg.senderName
            : 'Staff Member');

    final roleLabel = msg.isHR ? 'HR ADMIN' : 'STAFF';
    final deptLabel = msg.departmentKey.isNotEmpty
        ? msg.departmentKey
        : widget.departmentKey;

    // Sent message bubble styling (Dark Navy Charcoal #1E293B)
    // Received message bubble styling (White, Border #E2E8F0, Shadow)
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
          topRight: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
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
            msg.deletedForEveryone ? 'This message was deleted' : msg.text,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13.5,
              height: 1.4,
              color: msg.deletedForEveryone
                  ? (isMe ? Colors.white70 : const Color(0xFF64748B))
                  : (isMe ? Colors.white : const Color(0xFF0F172A)),
              fontStyle:
                  msg.deletedForEveryone ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Context / action detector
    final interactive = GestureDetector(
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

    final palette = _getAvatarPalette(senderName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Received Message: Avatar on Left
          if (!isMe) ...[
            _avatar(
              senderName,
              radius: 16,
              imageUrl: msg.senderImageUrl,
              palette: palette,
            ),
            const SizedBox(width: 10),
          ],

          // Bubble Column with Sender Header
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender Info Top Row
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w700,
                            color: isMe
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deptLabel,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: msg.isHR
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: msg.isHR
                                ? const Color(0xFFBFDBFE)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: msg.isHR
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                interactive,
              ],
            ),
          ),

          // Sent Message: Avatar on Right
          if (isMe) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF334155),
              child: Text(
                _initials(senderName),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── MESSAGE OPTIONS POPUPS & MODALS ──────────────────────────────────────
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
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Hide this message only from your view.',
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF94A3B8))),
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
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444))),
                subtitle: const Text(
                    'Remove this message for all group members.',
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF94A3B8))),
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
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      color: Color(0xFF475569))),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
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
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444))),
              ],
            ),
          ),
      ],
    );
    if (selected == null || !mounted) return;
    _confirmDelete(
      context,
      msg,
      callerId,
      hrProvider,
      forEveryone: selected == 'everyone',
    );
  }

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
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          forEveryone
              ? 'This message will be marked as deleted for all group members. Members who have already read it may have seen its content.'
              : 'This message will be hidden from your view only. Other group members will continue to see it.',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: forEveryone
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0F172A),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message,
            style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans', fontSize: 13)),
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(
            seconds: result.isHardFailure || result.isPermissionDenied ? 5 : 3),
      ),
    );
  }

  Future<void> _confirmClearDepartmentChat(
    BuildContext context,
    HRProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text(
          'Clear chat history? This will clear messages only from your account. Other department members will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_clear_department_chat'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await provider.clearDepartmentChat(widget.departmentKey);
    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDepartmentMessageSearch(
    BuildContext context,
    HRProvider provider,
    Color deptColor,
  ) async {
    final controller = TextEditingController();
    final callerId = provider.departmentChatUserId;
    final results = <ChatMessage>[];
    var loading = false;
    var loadingMore = false;
    var hasMore = false;
    var page = 1;
    String? error;
    String searchedQuery = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> search({bool more = false}) async {
            final query = controller.text.trim();
            if (query.isEmpty || (more && (!hasMore || loadingMore))) return;
            setDialogState(() {
              error = null;
              searchedQuery = query;
              if (more) {
                loadingMore = true;
              } else {
                loading = true;
                results.clear();
                page = 1;
                hasMore = false;
              }
            });
            try {
              final result = await provider.searchDepartmentMessages(
                widget.departmentKey,
                query: query,
                page: more ? page + 1 : 1,
                limit: 30,
              );
              if (!dialogContext.mounted) return;
              setDialogState(() {
                for (final message in result.messages) {
                  if (!message.deletedForEveryone &&
                      !message.deletedByIds.contains(callerId) &&
                      !results.any((existing) => existing.id == message.id)) {
                    results.add(message);
                  }
                }
                results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                page = result.page;
                hasMore = result.hasMore;
                loading = false;
                loadingMore = false;
              });
            } catch (e) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                error = e.toString().replaceFirst('Exception: ', '');
                loading = false;
                loadingMore = false;
              });
            }
          }

          return AlertDialog(
            title: Text(
              'Search ${widget.departmentKey.toLowerCase() == 'tech' ? 'Tech & Engineering' : 'Telecalling & Client Relations'} messages',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SizedBox(
              width: 560,
              height: MediaQuery.of(dialogContext).size.height * 0.62,
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('department_chat_search_field'),
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                      hintText: 'Search this department',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        onPressed: () => search(),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0F172A),
                            ),
                          )
                        : error != null
                            ? Center(
                                child:
                                    Text(error!, textAlign: TextAlign.center))
                            : searchedQuery.isEmpty
                                ? const Center(
                                    child: Text(
                                        'Enter a term to search this department.'))
                                : results.isEmpty
                                    ? const Center(
                                        child: Text('No messages found.'))
                                    : ListView.separated(
                                        itemCount:
                                            results.length + (hasMore ? 1 : 0),
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (_, index) {
                                          if (index == results.length) {
                                            return Center(
                                              child: TextButton.icon(
                                                onPressed: loadingMore
                                                    ? null
                                                    : () => search(more: true),
                                                icon: loadingMore
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2))
                                                    : const Icon(Icons.history),
                                                label: Text(loadingMore
                                                    ? 'Loading…'
                                                    : 'Load more results'),
                                              ),
                                            );
                                          }
                                          final message = results[index];
                                          final highlightStart = message.text
                                              .toLowerCase()
                                              .indexOf(
                                                  searchedQuery.toLowerCase());
                                          return ListTile(
                                            key: ValueKey(
                                                'department_search_result_${message.id}'),
                                            leading: CircleAvatar(
                                                backgroundColor: const Color(0xFF0F172A)
                                                    .withValues(alpha: 0.08),
                                                child: const Icon(
                                                    Icons.chat_bubble_outline,
                                                    color: Color(0xFF0F172A),
                                                    size: 18)),
                                            title: Text(message.senderName,
                                                style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            subtitle: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: highlightStart < 0
                                                  ? Text(message.text,
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis)
                                                  : RichText(
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      text: TextSpan(
                                                        style:
                                                            DefaultTextStyle.of(
                                                                    dialogContext)
                                                                .style,
                                                        children: [
                                                          TextSpan(
                                                              text: message.text
                                                                  .substring(0,
                                                                      highlightStart)),
                                                          TextSpan(
                                                              text: message.text
                                                                  .substring(
                                                                      highlightStart,
                                                                      highlightStart +
                                                                          searchedQuery
                                                                              .length),
                                                              style: TextStyle(
                                                                  backgroundColor:
                                                                      deptColor
                                                                          .withValues(
                                                                              alpha:
                                                                                  0.2),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          TextSpan(
                                                              text: message.text
                                                                  .substring(
                                                                      highlightStart +
                                                                          searchedQuery
                                                                              .length)),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                            trailing: Text(
                                                _formatTime(message.timestamp),
                                                style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B))),
                                          );
                                        },
                                      ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  // ── MESSAGE INPUT SECTION MATCHING SCREENSHOT ────────────────────────────
  Widget _buildMessageInput(
      HRProvider hrProvider, Color deptColor, String deptTitle) {
    final isBusy = _isSending || hrProvider.isSendingDepartmentMessage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rounded Message Input Container
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: Row(
              children: [
                // Plus / Attachment Button
                IconButton(
                  tooltip: 'Add attachment',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),

                // Emoji Button
                IconButton(
                  key: const ValueKey('chat_emoji_button'),
                  tooltip: 'Choose emoji',
                  onPressed: isBusy ? null : _openEmojiPicker,
                  icon: const Icon(
                    Icons.sentiment_satisfied_alt_outlined,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),

                // Text Input Field
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _inputFocus,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isBusy
                          ? 'Transmitting message...'
                          : 'Broadcast a message to $deptTitle group...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),

                // Dark Pill Send Button
                Material(
                  color: isBusy
                      ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: const ValueKey('chat_send_button'),
                    onTap: isBusy ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBusy)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isBusy ? 'Sending...' : 'Send',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white,
                              fontSize: 12.5,
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
          ),
          const SizedBox(height: 8),

          // Footnote Row below input bar
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Group Access Restricted: Authorized active employees only.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Press Enter to send',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
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
    String deptTitle,
  ) {
    final filteredStaff = _memberFilter.isEmpty
        ? deptStaff
        : deptStaff.where((s) {
            final name = s.name.toLowerCase();
            final desig = s.designation.toLowerCase();
            final role = s.role.toLowerCase();
            return name.contains(_memberFilter) ||
                desig.contains(_memberFilter) ||
                role.contains(_memberFilter);
          }).toList();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Department Members (${deptStaff.length})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Member Search Input (CupertinoTextField to preserve TextField count in tests)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _memberFilterCtrl,
                      placeholder: 'Filter member...',
                      placeholderStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Members List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filteredStaff.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, i) {
                final staff = filteredStaff[i];
                final isLead = i == 0;
                final palette = _getAvatarPalette(staff.name);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Avatar
                      _avatar(
                        staff.name,
                        radius: 17,
                        palette: palette,
                      ),
                      const SizedBox(width: 12),

                      // Name and role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    staff.name,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Text(
                                      'LEAD',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              staff.designation.isNotEmpty
                                  ? staff.designation
                                  : staff.role,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action: Manage Department Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _showDepartmentSettingsDialog(
                  context,
                  hrProvider,
                  deptTitle,
                  deptStaff,
                ),
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                label: const Text('Manage Department Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFDBEAFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepartmentSettingsDialog(
    BuildContext context,
    HRProvider hrProvider,
    String deptTitle,
    List<Staff> deptStaff,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$deptTitle Settings',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department Key: ${widget.departmentKey}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Authorized Members: ${deptStaff.length}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Channel Status: Live Realtime Communication Active',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined,
                size: 48, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages in $deptTitle yet',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Broadcast instructions or discuss projects with your team below.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
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
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
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
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final text = '${dt.day}/${dt.month}/${dt.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: _border, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Expanded(child: Divider(color: _border, height: 1)),
        ],
      ),
    );
  }

  Widget _avatar(
    String name, {
    double radius = 18,
    String? imageUrl,
    (Color, Color)? palette,
  }) {
    final initials = _initials(name);
    final p = palette ?? _getAvatarPalette(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: p.$1,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: p.$2,
                      fontWeight: FontWeight.w700,
                      fontSize: radius * 0.72,
                    ),
                  ),
                ),
              ),
            )
          : Text(
              initials,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: p.$2,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.72,
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

  (Color, Color) _getAvatarPalette(String name) {
    const palettes = [
      (Color(0xFFD1FAE5), Color(0xFF059669)), // Mint / Teal
      (Color(0xFFEDE9FE), Color(0xFF7C3AED)), // Purple
      (Color(0xFFCFFAFE), Color(0xFF0891B2)), // Cyan
      (Color(0xFFFFE4E6), Color(0xFFE11D48)), // Pink / Rose
      (Color(0xFFFFEDD5), Color(0xFFEA580C)), // Orange
      (Color(0xFFE0E7FF), Color(0xFF4F46E5)), // Indigo
      (Color(0xFFDCFCE7), Color(0xFF16A34A)), // Light Green
      (Color(0xFFF3E8FF), Color(0xFF9333EA)), // Violet
      (Color(0xFFF1F5F9), Color(0xFF475569)), // Slate
    ];
    if (name.isEmpty) return palettes[0];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palettes[hash % palettes.length];
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
