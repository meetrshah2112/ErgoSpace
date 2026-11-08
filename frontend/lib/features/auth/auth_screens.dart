import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ergo_widgets.dart';
import 'auth_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: DotMatrix(spacing: 16)),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Wordmark(size: 26),
            const SizedBox(height: 20),
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: context.ergo.accent)),
          ])),
        ]),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Scaffold(
      body: Stack(children: [
        Positioned(left: 0, right: 0, top: 0, height: MediaQuery.of(context).size.height * .55, child: const DotMatrix(spacing: 16, radius: 1.6)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Wordmark(),
              const Spacer(),
              Text('Find your space.', style: TextStyle(fontSize: 40, height: 1.05, fontWeight: FontWeight.w800, color: c.text)),
              Text('Elevate your work.', style: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w800, color: c.accent)),
              const SizedBox(height: 16),
              Text('Spaces designed around the way you work.', style: TextStyle(fontSize: 16, color: c.textSecondary)),
              const SizedBox(height: 32),
              ErgoButton('Create account', onPressed: () => context.go('/register')),
              const SizedBox(height: 12),
              ErgoButton('I already have an account', secondary: true, onPressed: () => context.go('/login')),
            ]),
          ),
        ),
      ]),
    );
  }
}

String? vRequired(String? v, [String f = 'This field']) => (v == null || v.trim().isEmpty) ? '$f is required' : null;
String? vEmail(String? v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pw = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _pw.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text, _pw.text);
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = ApiException.from(e).message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/welcome'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome back.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Sign in to continue to your workspace.', style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 32),
              ErgoField(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress, validator: vEmail),
              const SizedBox(height: 16),
              ErgoField(label: 'Password', controller: _pw, obscure: true, validator: (v) => vRequired(v, 'Password')),
              if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: TextStyle(color: c.error))],
              const SizedBox(height: 28),
              ErgoButton('Sign in', loading: _busy, onPressed: _submit),
              const SizedBox(height: 16),
              Center(child: TextButton(onPressed: () => context.go('/register'), child: Text('New to ErgoSpace? Create account', style: TextStyle(color: c.textSecondary)))),
            ]),
          ),
        ),
      ),
    );
  }

}

class RegisterScreen extends ConsumerStatefulWidget {
  final String initialType;
  const RegisterScreen({super.key, this.initialType = 'customer'});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(), _last = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController();
  late String _type = widget.initialType == 'provider' ? 'provider' : 'customer';
  bool _busy = false;
  String? _error;
  Map<String, String> _fields = {};

  @override
  void dispose() { for (final c in [_first, _last, _email, _pw]) { c.dispose(); } super.dispose(); }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; _fields = {}; });
    try {
      await ref.read(authControllerProvider.notifier).register(
          first: _first.text, last: _last.text, email: _email.text, password: _pw.text, userType: _type);
    } catch (e) {
      final ex = ApiException.from(e);
      if (mounted) setState(() { _busy = false; _error = ex.fieldErrors.isEmpty ? ex.message : null; _fields = ex.fieldErrors; });
    }
  }

  Widget _typeCard(String value, String title, String sub, IconData icon) {
    final c = context.ergo;
    final sel = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? c.surface2 : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? c.accent : c.border, width: sel ? 1.6 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: sel ? c.accent : c.textSecondary),
              Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? c.accent : c.border, width: 2), color: sel ? c.accent : Colors.transparent)),
            ]),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/welcome'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create your account.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('How will you use ErgoSpace?', style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 20),
              Row(children: [
                _typeCard('customer', 'Find a workspace', 'Customer', Icons.search_rounded),
                const SizedBox(width: 12),
                _typeCard('provider', 'List your workspace', 'Provider', Icons.apartment_rounded),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: ErgoField(label: 'First name', controller: _first, validator: (v) => vRequired(v, 'First name'), errorText: _fields['first_name'])),
                const SizedBox(width: 12),
                Expanded(child: ErgoField(label: 'Last name', controller: _last, validator: (v) => vRequired(v, 'Last name'), errorText: _fields['last_name'])),
              ]),
              const SizedBox(height: 16),
              ErgoField(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress, validator: vEmail, errorText: _fields['email']),
              const SizedBox(height: 16),
              ErgoField(label: 'Password', controller: _pw, obscure: true, errorText: _fields['password'],
                  validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null),
              if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: TextStyle(color: c.error))],
              const SizedBox(height: 28),
              ErgoButton('Create account', loading: _busy, onPressed: _submit),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => context.go('/login'), child: Text('Already registered? Sign in', style: TextStyle(color: c.textSecondary)))),
            ]),
          ),
        ),
      ),
    );
  }
}
