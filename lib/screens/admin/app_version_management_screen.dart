import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/services/r2_storage_service.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_text_field.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AppVersionManagementScreen extends StatefulWidget {
  const AppVersionManagementScreen({super.key});

  @override
  State<AppVersionManagementScreen> createState() =>
      _AppVersionManagementScreenState();
}

class _AppVersionManagementScreenState
    extends State<AppVersionManagementScreen> {
  // Use admin client with service role for bypassing RLS
  final SupabaseClient _supabase = AdminSupabaseClient.client;
  final R2StorageService _r2Service = R2StorageService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _versions = [];

  // Form Controllers
  final _versionCodeController = TextEditingController();
  final _versionNameController = TextEditingController();
  final _releaseNotesController = TextEditingController();
  final _downloadUrlController = TextEditingController();
  bool _forceUpdate = false;
  File? _selectedApk;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('app_versions')
          .select()
          .order('version_code', ascending: false);
      setState(() {
        _versions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showError('Failed to load versions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickApk() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedApk = File(result.files.single.path!);
          // Clear manual URL if APK picked
          _downloadUrlController.clear();
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<bool> _uploadAndSave() async {
    if (_versionCodeController.text.isEmpty ||
        _versionNameController.text.isEmpty) {
      _showError('Version Code and Name are required');
      return false;
    }

    if (_selectedApk == null && _downloadUrlController.text.isEmpty) {
      _showError('Please select an APK or enter a Download URL');
      return false;
    }

    setState(() => _isLoading = true);

    try {
      String downloadUrl = _downloadUrlController.text;

      if (_selectedApk != null) {
        final fileName =
            'app-release-v${_versionNameController.text}-${DateTime.now().millisecondsSinceEpoch}.apk';
        final path = 'updates/$fileName';

        final uploadedUrl = await _r2Service.uploadFile(
          file: _selectedApk!,
          path: path,
        );

        if (uploadedUrl == null) {
          throw Exception('Failed to upload APK to R2');
        }
        downloadUrl = uploadedUrl;
      }

      final versionCode = int.parse(_versionCodeController.text);

      debugPrint(
        '📤 Inserting version: code=$versionCode, name=${_versionNameController.text}',
      );
      debugPrint('📤 Download URL: $downloadUrl');

      try {
        await _supabase.schema('munajat_app').from('app_versions').insert({
          'version_code': versionCode,
          'version_name': _versionNameController.text,
          'release_notes': _releaseNotesController.text,
          'download_url': downloadUrl,
          'force_update': _forceUpdate,
        });
        debugPrint('✅ Insert completed');
      } catch (insertError) {
        debugPrint('❌ Insert error: $insertError');
        rethrow;
      }

      _clearForm();
      _loadVersions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Version published successfully')),
        );
      }
      return true;
    } catch (e) {
      debugPrint('❌ Full error: $e');
      _showError('Failed to publish: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddVersionDialog() {
    // Reset form
    _clearForm();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = GlassTheme.text(isDark);
          final accentColor = GlassTheme.accent(isDark);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: GlassCard(
              isDarkForce: isDark,
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish New Version',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassTextField(
                        controller: _versionCodeController,
                        hintText: 'Version Code (e.g. 21)',
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                        icon: Icons.numbers,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _versionNameController,
                        hintText: 'Version Name (e.g. 2.1.0)',
                        isDark: isDark,
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _releaseNotesController,
                        hintText: 'Release Notes',
                        maxLines: 3,
                        isDark: isDark,
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 20),

                      // APK Selector
                      Text(
                        'APK File',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _selectedApk != null
                                ? Text(
                                    _selectedApk!.path
                                        .split(Platform.pathSeparator)
                                        .last,
                                    style: TextStyle(color: accentColor),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'No file selected',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _pickApk();
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pick APK'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: accentColor,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // Or Manual URL
                      if (_selectedApk == null)
                        GlassTextField(
                          controller: _downloadUrlController,
                          hintText: 'Or Enter Direct Download URL',
                          isDark: isDark,
                          icon: Icons.link,
                        ),

                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: Text(
                          'Force Update?',
                          style: TextStyle(color: textColor),
                        ),
                        value: _forceUpdate,
                        onChanged: (val) =>
                            setDialogState(() => _forceUpdate = val ?? false),
                        activeColor: accentColor,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: () async {
                                setDialogState(() => _isLoading = true);
                                final success = await _uploadAndSave();
                                if (!context.mounted) return;

                                if (success) {
                                  Navigator.pop(
                                    context,
                                  ); // Close dialog on success
                                } else {
                                  // Only stop loading if not popped (failure case)
                                  setDialogState(() => _isLoading = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Publish'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _clearForm() {
    _versionCodeController.clear();
    _versionNameController.clear();
    _releaseNotesController.clear();
    _downloadUrlController.clear();
    setState(() {
      _selectedApk = null;
      _forceUpdate = false;
      _isLoading = false;
    });
  }

  void _showVersionDetails(
    Map<String, dynamic> version,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final date = DateTime.parse(version['created_at']).toLocal();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2E28) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: accentColor),
            const SizedBox(width: 8),
            Text('Version Details', style: TextStyle(color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Version Name', version['version_name'], textColor),
              _detailRow(
                'Version Code',
                '${version['version_code']}',
                textColor,
              ),
              _detailRow(
                'Force Update',
                version['force_update'] == true ? 'Yes' : 'No',
                textColor,
              ),
              _detailRow(
                'Created',
                DateFormat('MMM d, yyyy h:mm a').format(date),
                textColor,
              ),
              const Divider(height: 24),
              Text(
                'Release Notes',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                version['release_notes'] ?? 'No release notes',
                style: TextStyle(color: textColor.withValues(alpha: 0.8)),
              ),
              const Divider(height: 24),
              Text(
                'Download URL',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                version['download_url'] ?? 'N/A',
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVersionDialog(
    Map<String, dynamic> version,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    // Pre-fill form with existing values
    final editVersionCodeController = TextEditingController(
      text: '${version['version_code']}',
    );
    final editVersionNameController = TextEditingController(
      text: version['version_name'],
    );
    final editReleaseNotesController = TextEditingController(
      text: version['release_notes'] ?? '',
    );
    final editDownloadUrlController = TextEditingController(
      text: version['download_url'],
    );
    bool editForceUpdate = version['force_update'] == true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2E28) : Colors.white,
          title: Row(
            children: [
              Icon(Icons.edit, color: accentColor),
              const SizedBox(width: 8),
              Text('Edit Version', style: TextStyle(color: textColor)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassTextField(
                  controller: editVersionCodeController,
                  hintText: 'Version Code',
                  icon: Icons.numbers,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: editVersionNameController,
                  hintText: 'Version Name (e.g., 1.0.0)',
                  icon: Icons.label,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: editReleaseNotesController,
                  hintText: 'Release Notes',
                  icon: Icons.notes,
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: editDownloadUrlController,
                  hintText: 'Download URL',
                  icon: Icons.link,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: editForceUpdate,
                  onChanged: (v) =>
                      setDialogState(() => editForceUpdate = v ?? false),
                  title: Text(
                    'Force Update',
                    style: TextStyle(color: textColor),
                  ),
                  activeColor: accentColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              onPressed: () async {
                try {
                  await _supabase
                      .schema('munajat_app')
                      .from('app_versions')
                      .update({
                        'version_code': int.parse(
                          editVersionCodeController.text,
                        ),
                        'version_name': editVersionNameController.text,
                        'release_notes': editReleaseNotesController.text,
                        'download_url': editDownloadUrlController.text,
                        'force_update': editForceUpdate,
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('id', version['id']);

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _loadVersions();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Version updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  _showError('Failed to update: $e');
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVersion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Version'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase
          .schema('munajat_app')
          .from('app_versions')
          .delete()
          .eq('id', id);
      _loadVersions();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'App Version Control',
          body: _isLoading && _versions.isEmpty
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _versions.length,
                  itemBuilder: (context, index) {
                    final version = _versions[index];
                    final date = DateTime.parse(
                      version['created_at'],
                    ).toLocal();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        isDarkForce: isDark,
                        borderRadius: 16,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () => _showVersionDetails(
                            version,
                            isDark,
                            textColor,
                            accentColor,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: accentColor.withValues(alpha: 0.1),
                            child: Icon(Icons.android, color: accentColor),
                          ),
                          title: Text(
                            'v${version['version_name']} (${version['version_code']})',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy h:mm a').format(date),
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              if (version['force_update'] == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'FORCE UPDATE',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: textColor),
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _showVersionDetails(
                                    version,
                                    isDark,
                                    textColor,
                                    accentColor,
                                  );
                                  break;
                                case 'edit':
                                  _showEditVersionDialog(
                                    version,
                                    isDark,
                                    textColor,
                                    accentColor,
                                  );
                                  break;
                                case 'delete':
                                  _deleteVersion(version['id']);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: accentColor,
            onPressed: _showAddVersionDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Version'),
          ),
        );
      },
    );
  }
}
