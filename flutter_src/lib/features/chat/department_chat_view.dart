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

  static const Color _navy = Color(0xFF17243A);
  static const Color _sentBubble = Color(0xFF2457D6);
  static const Color _receivedBubble = Color(0xFFFFFFFF);
  static const Color _bgGray = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
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
                    const SizedBox(width: 8),
                    Container(
                      key: const ValueKey('chat_live_status_badge'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hrProvider.isChatSocketConnected
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hrProvider.isChatSocketConnected
                              ? const Color(0xFF86EFAC)
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
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hrProvider.isChatSocketConnected
                                ? 'Live Sync'
                                : 'Connecting...',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: hrProvider.isChatSocketConnected
                                  ? const Color(0xFF15803D)
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
          PopupMenuButton<String>(
            key: const ValueKey('department_chat_more_menu'),
            tooltip: 'Chat options',
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
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.search),
                  title: Text('Search messages'),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: !hrProvider.isDepartmentChatClearing,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cleaning_services_outlined),
                  title: Text(hrProvider.isDepartmentChatClearing
                      ? 'Clearing chat…'
                      : 'Clear chat'),
                ),
              ),
            ],
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
    final callerId = provider.currentUser?.id ?? '';
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
                'Search ${widget.departmentKey.toLowerCase() == 'tech' ? 'Tech & Engineering' : 'Telecalling & Client Relations'} messages'),
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
                        ? Center(
                            child: CircularProgressIndicator(color: deptColor))
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
                                                backgroundColor: deptColor
                                                    .withValues(alpha: 0.12),
                                                child: Icon(
                                                    Icons.chat_bubble_outline,
                                                    color: deptColor,
                                                    size: 18)),
                                            title: Text(message.senderName,
                                                style: const TextStyle(
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
                                                              text: message.text.substring(
                                                                  highlightStart,
                                                                  highlightStart +
                                                                      searchedQuery
                                                                          .length),
                                                              style: TextStyle(
                                                                  backgroundColor:
                                                                      deptColor.withValues(
                                                                          alpha:
                                                                              0.2),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          TextSpan(
                                                              text: message.text.substring(
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
                                        color: Color(0xFF2563EB)),
                                  )
                                : const Icon(Icons.history_rounded, size: 16),
                            label: Text(
                              hrProvider.isDepartmentChatLoadingMore
                                  ? 'Loading older messages...'
                                  : 'Load earlier messages (${hrProvider.departmentChatTotalMessages - visible.length} remaining)',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildGroupMessageBubble(
    ChatMessage msg,
    bool isMe,
    Color deptColor,
    String callerId,
    HRProvider hrProvider,
  ) {
    final timeStr = _formatTime(msg.timestamp);
    final canDeleteForEveryone =
        msg.senderId == callerId || hrProvider.isHRAdmin;

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
            msg.deletedForEveryone ? 'This message was deleted' : msg.text,
            style: TextStyle(
              fontSize: 14,
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
            _avatar(
              msg.senderName.isNotEmpty ? msg.senderName : 'Staff',
              radius: 16,
              imageUrl: msg.senderImageUrl,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isMe
                              ? (msg.senderName.isNotEmpty
                                  ? msg.senderName
                                  : 'You')
                              : (msg.senderName.isNotEmpty
                                  ? msg.senderName
                                  : 'Staff Member'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: deptColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (msg.departmentKey.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          msg.departmentKey,
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF64748B)),
                        ),
                      ],
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
                          msg.isHR ? 'HR ADMIN' : 'STAFF',
                          style: TextStyle(
                            fontSize: 9,
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
          if (isMe) ...[
            const SizedBox(width: 8),
            _avatar(
              msg.senderName.isNotEmpty ? msg.senderName : 'You',
              radius: 16,
              imageUrl: msg.senderImageUrl,
            ),
          ],
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

  Widget _buildMessageInput(
      HRProvider hrProvider, Color deptColor, String deptTitle) {
    final isBusy = _isSending || hrProvider.isSendingDepartmentMessage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('chat_emoji_button'),
            tooltip: 'Choose emoji',
            onPressed: isBusy ? null : _openEmojiPicker,
            icon: const Icon(Icons.emoji_emotions_outlined),
            color: deptColor,
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              focusNode: _inputFocus,
              minLines: 1,
              maxLines: 4,
              enabled: !isBusy,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: isBusy
                    ? 'Transmitting message...'
                    : 'Broadcast a message to $deptTitle group...',
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
            color: isBusy ? deptColor.withValues(alpha: 0.6) : deptColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              key: const ValueKey('chat_send_button'),
              onTap: isBusy ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    if (isBusy)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isBusy ? 'Sending...' : 'Send',
                      style: const TextStyle(
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

  Widget _avatar(String name, {double radius = 18, String? imageUrl}) {
    final initials = _initials(name);
    final color = _avatarColor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: radius * 0.75)),
                ),
              ),
            )
          : Text(
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
