import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isRegister => _tabs.index == 1;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<AuthViewModel>();
    vm.clearError();

    final ok = _isRegister
        ? await vm.register(_emailCtrl.text, _passwordCtrl.text, _nameCtrl.text)
        : await vm.signIn(_emailCtrl.text, _passwordCtrl.text);

    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        elevation: 0,
        title: Text(
          _isRegister ? 'Account erstellen' : 'Anmelden',
          style: TextStyle(color: C.text, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: C.text),
        bottom: TabBar(
          controller: _tabs,
          labelColor: C.accent,
          unselectedLabelColor: C.textSoft,
          indicatorColor: C.accent,
          tabs: const [
            Tab(text: 'Anmelden'),
            Tab(text: 'Registrieren'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Icon
                  Icon(Icons.shield, size: 56, color: C.accent),
                  const SizedBox(height: 8),
                  Text(
                    'DungeonManager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: C.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister
                        ? 'Erstelle deinen DM-Account für Cloud-Features'
                        : 'Melde dich an für Companion Mode & mehr',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: C.textSoft),
                  ),
                  const SizedBox(height: 32),

                  // Name (nur bei Register)
                  if (_isRegister) ...[
                    _field(
                      controller: _nameCtrl,
                      label: 'Anzeigename',
                      icon: Icons.person_outline,
                      C: C,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name erforderlich' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // E-Mail
                  _field(
                    controller: _emailCtrl,
                    label: 'E-Mail',
                    icon: Icons.email_outlined,
                    C: C,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Gültige E-Mail eingeben' : null,
                  ),
                  const SizedBox(height: 14),

                  // Passwort
                  _field(
                    controller: _passwordCtrl,
                    label: 'Passwort',
                    icon: Icons.lock_outline,
                    C: C,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: C.textSoft,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mindestens 6 Zeichen' : null,
                  ),
                  const SizedBox(height: 8),

                  // Fehlermeldung
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Submit-Button
                  FilledButton(
                    onPressed: vm.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: C.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isRegister ? 'Account erstellen' : 'Anmelden',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: C.border),
                  const SizedBox(height: 16),

                  // Lokal weiter
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Ohne Account fortfahren',
                      style: TextStyle(color: C.textSoft, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColorsExtension C,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: C.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: C.textSoft),
        prefixIcon: Icon(icon, color: C.textSoft, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: C.bgPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: C.accent, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
