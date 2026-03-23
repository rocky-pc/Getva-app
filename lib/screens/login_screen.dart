import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _goldDeep    = Color(0xFFB8892A);
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _violet      = Color(0xFF5A3FBF);
const _violetLight = Color(0xFF8B6FE8);
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);
const _inputBg     = Color(0xFF0D0B1A);

// ═══════════════════════════════════════════════════════════════
//  LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Login
  final _emailOrPhoneController = TextEditingController();
  final _passwordController     = TextEditingController();

  // Register
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController  = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword  = true;
  bool _isLoading    = false;
  bool _isRegistering = false;
  String? _errorMessage;

  // Animations
  late AnimationController _shimmerCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _switchCtrl;

  late Animation<double> _shimmerAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _switchAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo);

    _switchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _switchAnim = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeOutCubic);

    final rng = math.Random(11);
    for (int i = 0; i < 26; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.8 + 0.5,
        speed: rng.nextDouble() * 0.35 + 0.12,
        opacity: rng.nextDouble() * 0.4 + 0.07,
        phase: rng.nextDouble(),
      ));
    }

    Future.delayed(const Duration(milliseconds: 100),
            () { if (mounted) _entryCtrl.forward(); });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose(); _orbCtrl.dispose(); _pulseCtrl.dispose();
    _particleCtrl.dispose(); _entryCtrl.dispose(); _switchCtrl.dispose();
    _emailOrPhoneController.dispose(); _passwordController.dispose();
    _nameController.dispose(); _emailController.dispose();
    _phoneController.dispose(); _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool toRegister) {
    _switchCtrl.forward(from: 0).then((_) => _switchCtrl.reverse());
    setState(() { _isRegistering = toRegister; _errorMessage = null; });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await ApiService.login(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );
      if (result['success'] == true) {
        final userData = result['user'];
        await SessionManager.saveSession(
          userId: userData['id'] ?? 0,
          email: userData['email'] ?? _emailOrPhoneController.text.trim(),
          name: userData['name'],
        );
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _errorMessage =
            result['message'] ?? 'Login failed. Please try again.');
      }
    } catch (_) {
      setState(() =>
      _errorMessage = 'Connection error. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await ApiService.registerUser({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim() : null,
        'password': _registerPasswordController.text,
      });
      if (result['success'] == true || result['id'] != null) {
        if (mounted) {
          _showSuccessSnack('Account created! Please sign in.');
          setState(() {
            _isRegistering = false;
            _errorMessage = null;
            _emailOrPhoneController.text = _emailController.text.trim();
          });
        }
      } else {
        setState(() => _errorMessage =
            result['error'] ?? result['message'] ?? 'Registration failed.');
      }
    } catch (_) {
      setState(() =>
      _errorMessage = 'Connection error. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: _green, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(
            color: _textPrimary, fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: _cardBg2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _border)),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF080714), Color(0xFF0A0910), Color(0xFF060512)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),

          // ── Orbs ──
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100 + _orbAnim.value * 40,
                left: size.width / 2 - 200 + _orbAnim.value * 30,
                child: _OrbGlow(
                    color: _gold.withOpacity(0.16 + _pulseAnim.value * 0.06),
                    size: 420),
              ),
              Positioned(
                bottom: 60 + _orbAnim.value * -20,
                right: -80 + _orbAnim.value * 20,
                child: _OrbGlow(
                    color: _violet.withOpacity(0.12 + _pulseAnim.value * 0.04),
                    size: 300),
              ),
              Positioned(
                top: size.height * 0.4,
                left: -60,
                child: _OrbGlow(
                    color: _violetLight.withOpacity(0.07), size: 220),
              ),
            ]),
          ),

          // ── Particles ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                  particles: _particles, progress: _particleCtrl.value),
            ),
          ),

          // ── Noise ──
          Opacity(
            opacity: 0.022,
            child: CustomPaint(size: size, painter: _NoisePainter()),
          ),

          // ── Scroll content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHero(),
                  const SizedBox(height: 36),
                  _buildCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──
  Widget _buildHero() {
    return _AnimatedReveal(
      animation: _entryAnim,
      delay: 0.0,
      child: Column(
        children: [
          // Logo mark
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldBright],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.35 + _pulseAnim.value * 0.15),
                    blurRadius: 24 + _pulseAnim.value * 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('G',
                    style: TextStyle(
                        color: Color(0xFF1A1200),
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App name shimmer
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, child) => ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: const [_gold, _goldBright, _gold],
                begin: Alignment(-1.5 + _shimmerAnim.value * 4, 0),
                end: Alignment(-0.5 + _shimmerAnim.value * 4, 0),
              ).createShader(b),
              child: child!,
            ),
            child: const Text('GETVA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 8),

          // Tagline
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isRegistering
                  ? 'Create Account & Win Big! 🎁'
                  : 'Scratch & Win Exciting Rewards! ✨',
              key: ValueKey(_isRegistering),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──
  Widget _buildCard() {
    return _AnimatedReveal(
      animation: _entryAnim,
      delay: 0.15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF16132E), Color(0xFF0E0C1E)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Color.lerp(_border,
                      _gold.withOpacity(0.25), _pulseAnim.value)!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.06 + _pulseAnim.value * 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.04), end: Offset.zero)
                          .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                  child: _isRegistering
                      ? _buildRegisterFields(key: const ValueKey('register'))
                      : _buildLoginFields(key: const ValueKey('login')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Login fields ──
  Widget _buildLoginFields({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle('Welcome Back', 'Sign in to continue'),
        const SizedBox(height: 28),

        _DarkField(
          controller: _emailOrPhoneController,
          label: 'Email or Phone',
          hint: 'Enter email or phone',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter email or phone' : null,
        ),
        const SizedBox(height: 14),

        _DarkField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your password';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),

        Align(
          alignment: Alignment.centerRight,
          child: _TextLink(
            label: 'Forgot Password?',
            onTap: () => _showSuccessSnack('Forgot password coming soon!'),
          ),
        ),

        const SizedBox(height: 6),
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],

        _GoldButton(
          label: 'Sign In',
          isLoading: _isLoading,
          onTap: _login,
        ),
        const SizedBox(height: 20),

        _SwitchRow(
          question: "Don't have an account?",
          action: 'Register',
          onTap: () => _toggleMode(true),
        ),
      ],
    );
  }

  // ── Register fields ──
  Widget _buildRegisterFields({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle('Create Account', 'Join thousands of winners'),
        const SizedBox(height: 28),

        _DarkField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 14),

        _DarkField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),

        _DarkField(
          controller: _phoneController,
          label: 'Phone (Optional)',
          hint: 'Enter your phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        _DarkField(
          controller: _registerPasswordController,
          label: 'Password',
          hint: 'Create a password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureRegisterPassword,
          onToggleObscure: () => setState(
                  () => _obscureRegisterPassword = !_obscureRegisterPassword),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a password';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),

        _DarkField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          onToggleObscure: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _registerPasswordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],

        _GoldButton(
          label: 'Create Account',
          isLoading: _isLoading,
          onTap: _register,
        ),
        const SizedBox(height: 20),

        _SwitchRow(
          question: 'Already have an account?',
          action: 'Sign In',
          onTap: () => _toggleMode(false),
        ),
      ],
    );
  }

  Widget _cardTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4)),
        const SizedBox(height: 5),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DARK FIELD
// ═══════════════════════════════════════════════════════════════
class _DarkField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  State<_DarkField> createState() => _DarkFieldState();
}

class _DarkFieldState extends State<_DarkField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused ? _gold.withOpacity(0.5) : _border,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [BoxShadow(color: _gold.withOpacity(0.08), blurRadius: 12)]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(
              color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          cursorColor: _gold,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            labelStyle: TextStyle(
              color: _focused ? _gold.withOpacity(0.9) : _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(widget.icon,
                  color: _focused ? _gold : _textMuted, size: 18),
            ),
            prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.onToggleObscure != null
                ? GestureDetector(
              onTap: widget.onToggleObscure,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  widget.obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textMuted,
                  size: 18,
                ),
              ),
            )
                : null,
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _red, fontSize: 11),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GOLD BUTTON
// ═══════════════════════════════════════════════════════════════
class _GoldButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _GoldButton({
    Key? key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (!widget.isLoading) _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); if (!widget.isLoading) widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
            scale: 1.0 - _ctrl.value * 0.03, child: child),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? LinearGradient(colors: [
              _gold.withOpacity(0.5),
              _goldBright.withOpacity(0.5)
            ])
                : const LinearGradient(
              colors: [_gold, _goldBright, _goldDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading
                ? null
                : [
              BoxShadow(
                color: _gold.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFF1A1200)),
            )
                : Text(widget.label,
                style: const TextStyle(
                    color: Color(0xFF1A1200),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ERROR BANNER
// ═══════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: _red.withOpacity(0.9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: _red.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SWITCH ROW
// ═══════════════════════════════════════════════════════════════
class _SwitchRow extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const _SwitchRow({
    Key? key,
    required this.question,
    required this.action,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question,
            style: const TextStyle(
                color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        _TextLink(label: action, onTap: onTap),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TEXT LINK
// ═══════════════════════════════════════════════════════════════
class _TextLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextLink({Key? key, required this.label, required this.onTap})
      : super(key: key);

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.6 : 1.0,
        child: Text(widget.label,
            style: const TextStyle(
                color: _gold,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ANIMATED REVEAL
// ═══════════════════════════════════════════════════════════════
class _AnimatedReveal extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedReveal(
      {Key? key, required this.animation, required this.delay, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutExpo.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
              offset: Offset(0, 28 * (1 - curve)), child: child),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ORB GLOW
// ═══════════════════════════════════════════════════════════════
class _OrbGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _OrbGlow({Key? key, required this.color, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, radius, speed, opacity, phase;
  const _Particle({required this.x, required this.y, required this.radius,
    required this.speed, required this.opacity, required this.phase});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      final fade = (1 - (y < 0.15 ? (0.15 - y) / 0.15 : 0)) *
          (y > 0.85 ? (1.0 - y) / 0.15 : 1);
      paint.color = (i % 3 != 0 ? _gold : _violetLight)
          .withOpacity(p.opacity * fade);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  NOISE PAINTER
// ═══════════════════════════════════════════════════════════════
class _NoisePainter extends CustomPainter {
  final _rng = math.Random(22);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 1800; i++) {
      paint.color = Colors.white.withOpacity(_rng.nextDouble() * 0.5);
      canvas.drawCircle(
          Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
          _rng.nextDouble() * 0.65, paint);
    }
  }
  @override
  bool shouldRepaint(_NoisePainter _) => false;
}