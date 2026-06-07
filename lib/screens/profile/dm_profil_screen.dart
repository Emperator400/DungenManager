import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../services/campaign_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../auth/login_screen.dart';

class DmProfilScreen extends StatefulWidget {
  const DmProfilScreen({super.key});

  @override
  State<DmProfilScreen> createState() => _DmProfilScreenState();
}

class _DmProfilScreenState extends State<DmProfilScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: C.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('DM-Profil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: C.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAccountSection(context, C, auth),
          const SizedBox(height: 20),
          if (auth.isLoggedIn) ...[
            _buildCloudSyncSection(context, C, auth),
            const SizedBox(height: 20),
          ],
          _buildAppInfoSection(C),
        ],
      ),
    );
  }

  // ── Account ───────────────────────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context, AppColorsExtension C, AuthViewModel auth) {
    return _Section(
      C: C,
      title: 'Account',
      child: auth.isLoggedIn
          ? _buildLoggedInContent(context, C, auth)
          : _buildLoggedOutContent(context, C),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppColorsExtension C, AuthViewModel auth) {
    final user = auth.user!;
    return Column(
      children: [
        // Avatar + Infos
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: C.accent,
              child: Text(
                user.initials,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Kein Name',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 2),
                    Text(user.email!, style: TextStyle(fontSize: 12, color: C.textSoft)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: C.border),
        const SizedBox(height: 4),
        _ActionRow(
          C: C,
          icon: Icons.logout,
          label: 'Abmelden',
          destructive: true,
          onTap: () {
            context.read<AuthViewModel>().signOut();
          },
        ),
      ],
    );
  }

  Widget _buildLoggedOutContent(BuildContext context, AppColorsExtension C) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: C.bgHover,
                shape: BoxShape.circle,
                border: Border.all(color: C.border),
              ),
              child: Icon(Icons.person_outline, color: C.textSoft, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nicht angemeldet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                Text('Kampagnen werden nur lokal gespeichert', style: TextStyle(fontSize: 11, color: C.textSoft)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PrimaryBtn(
          C: C,
          label: 'Anmelden / Registrieren',
          icon: Icons.login,
          onTap: () async {
            final loggedIn = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
            );
            if (loggedIn == true && context.mounted) setState(() {});
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Mit einem Account kannst du Kampagnen in der Cloud sichern und zwischen Geräten synchronisieren.',
          style: TextStyle(fontSize: 11, color: C.textSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Cloud Sync ────────────────────────────────────────────────────────────

  Widget _buildCloudSyncSection(BuildContext context, AppColorsExtension C, AuthViewModel auth) {
    return Consumer<CampaignViewModel>(
      builder: (context, vm, _) {
        final lastSync = vm.lastSyncedAt;
        final syncError = vm.syncError;

        return _Section(
          C: C,
          title: 'Cloud-Synchronisierung',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 16, color: C.textSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastSync != null
                          ? 'Zuletzt synchronisiert: ${_formatTime(lastSync)}'
                          : 'Noch nicht synchronisiert',
                      style: TextStyle(fontSize: 12, color: C.textSoft),
                    ),
                  ),
                ],
              ),
              if (syncError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Text(syncError, style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
              const SizedBox(height: 12),
              if (vm.isSyncing)
                Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.accent)),
                    const SizedBox(width: 10),
                    Text('Synchronisiere...', style: TextStyle(fontSize: 12, color: C.textSoft)),
                  ],
                )
              else
                _PrimaryBtn(
                  C: C,
                  label: 'Jetzt synchronisieren',
                  icon: Icons.sync,
                  onTap: () => _runSync(context, auth, vm),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runSync(BuildContext context, AuthViewModel auth, CampaignViewModel vm) async {
    final user = auth.user;
    if (user == null) return;
    final syncService = context.read<CampaignSyncService>();
    await vm.syncWithCloud(user, syncService);
    if (!mounted) return;
    if (vm.syncError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: ${vm.syncError}'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisierung abgeschlossen')),
      );
    }
  }

  // ── App-Info ──────────────────────────────────────────────────────────────

  Widget _buildAppInfoSection(AppColorsExtension C) {
    return _Section(
      C: C,
      title: 'App',
      child: Column(
        children: [
          _InfoRow(C: C, label: 'Version', value: _version.isEmpty ? '…' : _version),
          Divider(color: C.border, height: 16),
          _InfoRow(C: C, label: 'System', value: 'D&D 5e'),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.C, required this.title, required this.child});

  final AppColorsExtension C;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.textSoft, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.C, required this.icon, required this.label, required this.onTap, this.destructive = false});

  final AppColorsExtension C;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : C.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.C, required this.label, required this.icon, required this.onTap});

  final AppColorsExtension C;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: C.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.C, required this.label, required this.value});

  final AppColorsExtension C;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: C.textSoft)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.text)),
      ],
    );
  }
}
