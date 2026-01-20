import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_service.dart';
import 'package:munajat_e_maqbool_app/services/masjid_manager_service.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_registration_screen.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_edit_screen.dart';

class MasjidManagerDashboard extends StatefulWidget {
  const MasjidManagerDashboard({super.key});

  @override
  State<MasjidManagerDashboard> createState() => _MasjidManagerDashboardState();
}

class _MasjidManagerDashboardState extends State<MasjidManagerDashboard> {
  final MasjidService _masjidService = MasjidService();
  final MasjidManagerService _managerService = MasjidManagerService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _myMasjids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyMasjids();
  }

  Future<void> _loadMyMasjids() async {
    setState(() => _isLoading = true);
    try {
      final masjids = await _masjidService.getMyMasjids();
      if (mounted) {
        setState(() {
          _myMasjids = masjids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  void _editJamatTimes(Map<String, dynamic> masjid) {
    showDialog(
      context: context,
      builder: (context) => _JamatTimeEditorDialog(
        masjidId: masjid['id'],
        initialTimes: {}, // Will be loaded in dialog or passed
        onSave: _loadMyMasjids,
      ),
    );
  }

  void _editMasjidInfo(Map<String, dynamic> masjid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MasjidEditScreen(masjid: masjid, onSaved: _loadMyMasjids),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    if (_authService.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Login to manage masjids',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: GlassTheme.background(isDark)),
          const AppBackgroundPattern(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Masjid Manager',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: accentColor),
                    onPressed: _loadMyMasjids,
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(accentColor, isDark),
                      const SizedBox(height: 24),
                      Text(
                        'My Masjids',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _myMasjids.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/icon_masjid.png',
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You haven\'t registered any masjids yet',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final masjid = _myMasjids[index];
                        return _buildMasjidCard(
                          masjid,
                          accentColor,
                          textColor,
                          isDark,
                        );
                      }, childCount: _myMasjids.length),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color accentColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Register New',
            icon: Icons.add_location_alt_rounded,
            color: accentColor,
            isDark: isDark,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MasjidRegistrationScreen(),
              ),
            ).then((_) => _loadMyMasjids()),
          ),
        ),
      ],
    );
  }

  Widget _buildMasjidCard(
    Map<String, dynamic> masjid,
    Color accent,
    Color textColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/icons/icon_masjid.png'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        masjid['name'],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        masjid['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(masjid['status']),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.visibility_rounded,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MasjidDetailScreen(masjidId: masjid['id']),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.3)),
                    ),
                    onPressed: () => _editJamatTimes(masjid),
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: const Text('Jamat Times'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.3)),
                    ),
                    onPressed: () => _editMasjidInfo(masjid),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Edit Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onPressed,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _JamatTimeEditorDialog extends StatefulWidget {
  final String masjidId;
  final Map<String, String> initialTimes;
  final VoidCallback onSave;

  const _JamatTimeEditorDialog({
    required this.masjidId,
    required this.initialTimes,
    required this.onSave,
  });

  @override
  State<_JamatTimeEditorDialog> createState() => _JamatTimeEditorDialogState();
}

class _JamatTimeEditorDialogState extends State<_JamatTimeEditorDialog> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jummah'].forEach((key) {
      _controllers[key] = TextEditingController();
    });
    _loadCurrentTimes();
  }

  Future<void> _loadCurrentTimes() async {
    final data = await MasjidService().getMasjidDetails(widget.masjidId);
    if (data != null && data['jamat_times'] != null) {
      setState(() {
        final times = data['jamat_times'] as Map<String, dynamic>;
        times.forEach((key, value) {
          if (_controllers.containsKey(key)) {
            _controllers[key]!.text = value?.toString() ?? '';
          }
        });
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final times = _controllers.map(
        (key, controller) => MapEntry(key, controller.text.trim()),
      );
      await MasjidManagerService().updateJamatTimes(widget.masjidId, times);
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    return AlertDialog(
      backgroundColor: isDark
          ? Colors.grey[900]?.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Edit Jamat Times', style: TextStyle(color: textColor)),
      content: SingleChildScrollView(
        child: Column(
          children: _controllers.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: e.value,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: e.key.toUpperCase(),
                  labelStyle: TextStyle(color: accentColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        _isSaving
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: const Text('Save'),
              ),
      ],
    );
  }
}
