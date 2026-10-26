import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/api_service.dart';
import '../../services/login_debug_logger.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  String? _localError;
  bool _isConsoleExpanded = true;
  bool _showToken = false;
  bool _pauseRedirect = false;

  @override
  void initState() {
    super.initState();
    LoginDebugLogger.instance.addListener(_onNewLog);
  }

  void _onNewLog() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    LoginDebugLogger.instance.removeListener(_onNewLog);
    _emailController.dispose();
    _passwordController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(HRProvider hrProvider) async {
    // Prevent multiple requests if already loading
    if (hrProvider.isLoginLoading) return;

    setState(() {
      _localError = null;
    });
    hrProvider.clearLoginError();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    LoginDebugLogger.instance.logLoginClick(email);

    await hrProvider.loginWithApi(
      email,
      password,
      autoNavigate: !_pauseRedirect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final isLoading = hrProvider.isLoginLoading;
    final errorMessage = _localError ??
        (hrProvider.loginError.isNotEmpty ? hrProvider.loginError : null);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              if (errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    border: Border.all(
                                        color: const Color(0xFFFCA5A5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
                                keyboardType: TextInputType.emailAddress,
                                enabled: !isLoading,
                                autocorrect: false,
                                validator: (value) {
                                  final val = value?.trim() ?? '';
                                  if (val.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  final emailRegex =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(val)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                    labelText: 'Password'),
                                obscureText: true,
                                enabled: !isLoading,
                                validator: (value) {
                                  final val = value?.trim() ?? '';
                                  if (val.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) =>
                                    _submitLogin(hrProvider),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _submitLogin(hrProvider),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Sign In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Success navigation banner when "Pause auto-redirect" is enabled
                  if (_pauseRedirect && hrProvider.currentUser != null) ...[
                    const SizedBox(height: 20),
                    _buildProceedBanner(hrProvider),
                  ],

                  const SizedBox(height: 32),

                  // Collapsible Login Debug Console
                  _buildDebugConsole(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProceedBanner(HRProvider hrProvider) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentication Succeeded!',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'User: ${hrProvider.currentUser?.name} (${hrProvider.currentUser?.role}). Pause-redirect mode is active.',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            key: const Key('proceed_to_dashboard_button'),
            onPressed: () => hrProvider.proceedToDashboard(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Proceed to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugConsole(BuildContext context) {
    final logger = LoginDebugLogger.instance;
    final logCount = logger.entries.length;
    final rawToken = logger.extractedToken ?? ApiService.token;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            key: const Key('toggle_debug_console'),
            onTap: () {
              setState(() {
                _isConsoleExpanded = !_isConsoleExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.terminal, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Login Debug Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$logCount events',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isConsoleExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          if (_isConsoleExpanded) ...[
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Controls & Token Summary Toolbar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Show/Hide Token Button
                  ElevatedButton.icon(
                    key: const Key('toggle_token_visibility'),
                    onPressed: () {
                      setState(() {
                        _showToken = !_showToken;
                      });
                    },
                    icon: Icon(
                      _showToken ? Icons.visibility_off : Icons.visibility,
                      size: 14,
                    ),
                    label: Text(
                      _showToken ? 'Hide Token' : 'Show Token',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                  // Clear Logs Button
                  ElevatedButton.icon(
                    key: const Key('clear_logs_button'),
                    onPressed: () {
                      logger.clear();
                    },
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text(
                      'Clear Logs',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFFF87171),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                  // Pause redirect toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _pauseRedirect,
                          activeColor: const Color(0xFF38BDF8),
                          checkColor: Colors.black,
                          side: const BorderSide(color: Color(0xFF64748B)),
                          onChanged: (val) {
                            setState(() {
                              _pauseRedirect = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pause redirect',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Token path pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      'Path: ${logger.tokenJsonPath ?? "none"}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF93C5FD),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  // Stored state pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: (logger.isTokenStored || ApiService.hasToken)
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (logger.isTokenStored || ApiService.hasToken)
                            ? const Color(0xFF059669)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      'Stored: ${(logger.isTokenStored || ApiService.hasToken) ? "YES" : "NO"}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: (logger.isTokenStored || ApiService.hasToken)
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Token Display Section (if token is present or diagnostic warning)
            if (rawToken != null && rawToken.isNotEmpty) ...[
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'Authentication Token:',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (kDebugMode)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: rawToken));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Token copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.copy,
                                      color: Color(0xFF38BDF8), size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (kDebugMode)
                      SelectableText(
                        _showToken
                            ? rawToken
                            : _maskTokenForDisplay(rawToken),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF34D399),
                        ),
                      )
                    else
                      const Text(
                        '[Protected - Token logging and visibility is disabled in production builds for security]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (logger.isTokenMissing &&
                logger.lastStatusCode != null &&
                logger.lastStatusCode == 200) ...[
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF450A0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF87171), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diagnostic Warning: Login returned 200 OK, but no token was found in fields "data.token" or "data.accessToken".',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Scrollable Console Log Output
            Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617), // Deep terminal black
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: logger.entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Console idle. Sign in to inspect live request/response tokens.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      itemCount: logger.entries.length,
                      itemBuilder: (context, index) {
                        final entry = logger.entries[index];
                        return _buildLogEntryRow(entry);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogEntryRow(LoginDebugEntry entry) {
    Color levelColor;
    String prefix;

    switch (entry.level) {
      case 'request':
        levelColor = const Color(0xFF38BDF8); // Cyan
        prefix = 'REQ';
        break;
      case 'response':
        levelColor = const Color(0xFFA78BFA); // Violet
        prefix = 'RES';
        break;
      case 'success':
        levelColor = const Color(0xFF34D399); // Green
        prefix = 'SUCCESS';
        break;
      case 'warning':
        levelColor = const Color(0xFFFBBF24); // Amber
        prefix = 'WARN';
        break;
      case 'error':
        levelColor = const Color(0xFFF87171); // Red
        prefix = 'ERROR';
        break;
      case 'json':
        levelColor = const Color(0xFF94A3B8); // Slate
        prefix = 'JSON';
        break;
      case 'token':
        levelColor = const Color(0xFF2DD4BF); // Teal
        prefix = 'TOKEN';
        break;
      default:
        levelColor = const Color(0xFFE2E8F0); // White
        prefix = 'INFO';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${entry.formattedTime}] ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: levelColor.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Text(
              prefix,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: levelColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskTokenForDisplay(String token) {
    if (token.length <= 20) {
      return '••••••••••••••••••••';
    }
    final start = token.substring(0, 14);
    final end = token.substring(token.length - 8);
    return '$start...[HIDDEN - Click "Show Token" to Reveal]...$end';
  }
}
