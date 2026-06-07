import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginEmail = TextEditingController(text: '');
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regPass2 = TextEditingController();
  final _regDept = TextEditingController();
  final _serverUrl = TextEditingController();
  String _regRole = 'student';
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await ApiService.getBaseUrl();
    _serverUrl.text = url;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) return;
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().login(_loginEmail.text, _loginPass.text);
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) showError(context, err);
    }
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) return;
    if (_regPass.text != _regPass2.text) {
      showError(context, 'Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().register(
          fullName: _regName.text,
          email: _regEmail.text,
          password: _regPass.text,
          role: _regRole,
          department: _regDept.text,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        showError(context, err);
      } else {
        showSuccess(context, 'Account created! You can now sign in.');
        _tab.animateTo(0);
        _loginEmail.text = _regEmail.text;
      }
    }
  }

  Future<void> _saveUrl() async {
    await ApiService.setBaseUrl(_serverUrl.text.trim());
    if (mounted) showSuccess(context, 'Server URL saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen gradient (must be sized; unbounded Stack breaks Scaffold body)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.8),
                  radius: 1.5,
                  colors: [Color(0xFF0D2540), AppTheme.bgDark],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Icon(Icons.account_balance_rounded, size: 28, color: AppTheme.teal),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(text: 'AI', style: TextStyle(color: AppTheme.teal)),
                            TextSpan(text: '-SCRMS', style: TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('AI-Powered Smart Campus Resource Management',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.bgCardBorder),
                    ),
                    child: Column(
                      children: [
                        // Tabs
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: TabBar(
                            controller: _tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: AppTheme.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppTheme.bgDark,
                            unselectedLabelColor: AppTheme.textSecondary,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                            tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          // TabBarView must not live inside a vertical scroll: it needs a bounded height.
                          child: AnimatedBuilder(
                            animation: _tab,
                            builder: (context, _) =>
                                _tab.index == 0 ? _loginForm() : _registerForm(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Demo credentials
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.key_rounded, color: AppTheme.teal, size: 16),
                            SizedBox(width: 8),
                            Text('Demo Accounts (password: password)',
                                style: TextStyle(
                                    color: AppTheme.teal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...[
                          ('Admin', 'admin@campus.edu'),
                          ('Faculty', 'kwame@campus.edu'),
                          ('Student', 'ama@campus.edu'),
                          ('Facility Mgr', 'fm@campus.edu'),
                        ].map((e) => InkWell(
                              onTap: () {
                                _loginEmail.text = e.$2;
                                _loginPass.text = 'password';
                                _tab.animateTo(0);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(e.$1,
                                          style: const TextStyle(
                                              color: AppTheme.amber,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text(e.$2,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),

                  // Server URL
                  const SizedBox(height: 16),
                  ExpansionTile(
                    leading: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 20),
                    title: const Text('Server Settings',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _serverUrl,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Backend URL',
                                hintText: 'http://192.168.x.x/ai_scrms',
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _saveUrl,
                                child: const Text('Save URL'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPass,
          obscureText: _obscurePass,
          style: const TextStyle(color: AppTheme.textPrimary),
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign In →'),
          ),
        ),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _regName,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regPass,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _regPass2,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Confirm'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Role'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _regRole,
                    dropdownColor: AppTheme.bgCard,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                    ],
                    onChanged: (v) => setState(() => _regRole = v ?? 'student'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _regDept,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Department'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create Account →'),
          ),
        ),
      ],
    );
  }
}
