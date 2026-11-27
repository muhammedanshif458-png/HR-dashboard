import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    await hrProvider.loginWithApi(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final isLoading = hrProvider.isLoginLoading;
    final errorMessage = _localError ??
        (hrProvider.loginError.isNotEmpty ? hrProvider.loginError : null);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;

              return Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 960 : 460,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 40,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isDesktop
                      ? SizedBox(
                          height: 580,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: _buildFormPanel(
                                      hrProvider: hrProvider,
                                      isLoading: isLoading,
                                      errorMessage: errorMessage,
                                      isDesktop: true,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 12,
                                child: _buildEditorialImage(),
                              ),
                            ],
                          ),
                        )
                      : _buildFormPanel(
                          hrProvider: hrProvider,
                          isLoading: isLoading,
                          errorMessage: errorMessage,
                          isDesktop: false,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static const _fontFallback = [
    'Plus Jakarta Sans',
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  // ── Login form design tokens ──────────────────────────────────────────────
  static const Color _textPrimary = Color(0xFF0A0A0A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _fieldFill = Color(0xFFF7F7F8);
  static const Color _fieldBorder = Color(0xFFE5E7EB);
  static const Color _fieldBorderFocused = Color(0xFF0A0A0A);
  static const double _radius = 10;
  static const double _formMaxWidth = 420;
  // Flutter adds a 4px gap after a prefixIcon, so 12 + 4 = 16px text inset.
  static const double _fieldInset = 12;

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    height: 1.2,
    color: _textMuted,
    fontFamilyFallback: _fontFallback,
  );

  static const TextStyle _fieldTextStyle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _textPrimary,
    fontFamilyFallback: _fontFallback,
  );

  /// One shared decoration so the email and password fields look identical
  /// (same fill, border, radius, inner padding and height).
  InputDecoration _fieldDecoration({
    required String hintText,
    required String semanticsLabel,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: _fontFallback,
      ),
      // Hidden label kept for widget tests / accessibility. When a prefixIcon
      // is present Flutter drops contentPadding's start inset, so this slot
      // (plus Flutter's 4px prefix gap) provides the 16px left inset.
      prefixIcon: SizedBox(
        width: _fieldInset,
        height: 0,
        child: Opacity(
          opacity: 0,
          child: Text(semanticsLabel,
              style:
                  const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 0)),
        ),
      ),
      prefixIconConstraints: const BoxConstraints.tightFor(width: _fieldInset),
      suffixIcon: suffixIcon,
      // Same fixed slot for both fields so the eye icon never changes height.
      suffixIconConstraints:
          const BoxConstraints(minWidth: 44, maxWidth: 44, minHeight: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: _fieldFill,
      border: border(_fieldBorder),
      enabledBorder: border(_fieldBorder),
      disabledBorder: border(_fieldBorder),
      focusedBorder: border(_fieldBorderFocused, 1.5),
      errorBorder: border(const Color(0xFFDC2626)),
      focusedErrorBorder: border(const Color(0xFFDC2626), 1.5),
    );
  }

  Widget _buildFormPanel({
    required HRProvider hrProvider,
    required bool isLoading,
    required String? errorMessage,
    required bool isDesktop,
  }) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 44.0 : (isNarrow ? 24.0 : 28.0),
        vertical: isDesktop ? 40.0 : 32.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _formMaxWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand logo (left-aligned with the form fields)
                Image.asset(
                  'assets/images/ly-softwares-logo.png',
                  height: isNarrow ? 32 : 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'LY Softwares',
                ),
                const SizedBox(height: 32),

                // Heading & subtitle
                const Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: Text('Login',
                          style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 0)),
                    ),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                        fontFamilyFallback: _fontFallback,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'live Young',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: _textMuted,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                    height: 1.3,
                    fontFamilyFallback: _fontFallback,
                  ),
                ),
                const SizedBox(height: 28),

                // Error banner
                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamilyFallback: _fontFallback,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // EMAIL
                const Text('EMAIL*', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hintText: 'aj@social.com',
                    semanticsLabel: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  autocorrect: false,
                  validator: (value) {
                    final val = value?.trim() ?? '';
                    if (val.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(val)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // PASSWORD label row: label left, "Forgot password?" flush right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('PASSWORD*', style: _labelStyle),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please contact your HR administrator to reset your password.',
                              style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: _textMuted,
                        textStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                          height: 1.2,
                          fontFamilyFallback: _fontFallback,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hintText: '••••••••••••',
                    semanticsLabel: 'Password',
                    suffixIcon: IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 40, height: 24),
                      splashRadius: 18,
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  enabled: !isLoading,
                  validator: (value) {
                    final val = value?.trim() ?? '';
                    if (val.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submitLogin(hrProvider),
                ),
                const SizedBox(height: 28),

                // Submit button: same width as the fields
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _textPrimary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                    ),
                    onPressed:
                        isLoading ? null : () => _submitLogin(hrProvider),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.0,
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'Log in',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                  fontFamilyFallback: _fontFallback,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialImage() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/images/auth_vinyl.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'auth_vinyl.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackPanel(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildFallbackPanel();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF32231A),
            Color(0xFF221711),
            Color(0xFF140D0A),
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SOUND SPECTRUM RECORDS',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFFE2E8F0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.album_outlined,
                color: Color(0xFFD7CCC8),
                size: 22,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LY SOFTWARE',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Empowering modern teams with seamless workforce management.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
