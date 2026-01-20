import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_text_field.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_manager_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_location_picker.dart';

class MasjidEditScreen extends StatefulWidget {
  final Map<String, dynamic> masjid;
  final VoidCallback onSaved;

  const MasjidEditScreen({
    super.key,
    required this.masjid,
    required this.onSaved,
  });

  @override
  State<MasjidEditScreen> createState() => _MasjidEditScreenState();
}

class _MasjidEditScreenState extends State<MasjidEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _bayanController;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  double? _lat;
  double? _lng;

  late Map<String, bool> _facilities;
  late List<String> _bayanLangs;

  final MasjidManagerService _managerService = MasjidManagerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.masjid['name']);
    _descController = TextEditingController(text: widget.masjid['description']);
    _addressController = TextEditingController(text: widget.masjid['address']);
    _contactPhoneController = TextEditingController(
      text: widget.masjid['contact_number'],
    );
    _bayanController = TextEditingController();
    _lat = widget.masjid['lat'];
    _lng = widget.masjid['long'];

    _facilities = Map<String, bool>.from(widget.masjid['facilities'] ?? {});
    _bayanLangs = List<String>.from(widget.masjid['bayan_languages'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    _bayanController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ShopLocationPicker(initialLat: _lat, initialLng: _lng),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lat = result['lat'] as double?;
        _lng = result['lng'] as double?;
        _addressController.text = result['address'] as String? ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _managerService.updateMasjidInfo(widget.masjid['id'], {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'contact_number': _contactPhoneController.text.trim(),
        'lat': _lat,
        'long': _lng,
        'facilities': _facilities,
        'bayan_languages': _bayanLangs,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masjid info updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update masjid: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = GlassTheme.accent(isDark);
    final textColor = GlassTheme.text(isDark);

    return GlassScaffold(
      title: 'Edit Masjid Info',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassTextField(
                controller: _nameController,
                hintText: 'Masjid Name',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/icons/icon_masjid.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                isDark: isDark,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickLocation,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: accentColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _addressController.text.isEmpty
                              ? 'Select Location on Map'
                              : _addressController.text,
                          style: TextStyle(
                            color: _addressController.text.isEmpty
                                ? textColor.withValues(alpha: 0.5)
                                : textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.map_rounded, size: 18, color: accentColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GlassTextField(
                controller: _contactPhoneController,
                hintText: 'Contact Number',
                icon: Icons.phone_rounded,
                isDark: isDark,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              GlassTextField(
                controller: _descController,
                hintText: 'Description / Instructions',
                icon: Icons.description_rounded,
                isDark: isDark,
                maxLines: 4,
              ),

              const SizedBox(height: 24),
              Text(
                'Facilities',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFacilitiesGrid(accentColor, textColor),

              const SizedBox(height: 24),
              Text(
                'Bayan Languages',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildBayanLangsEditor(accentColor, textColor, isDark),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _bayanController,
                      hintText: 'Add Language (e.g. Myanamr, Arabic)',
                      isDark: isDark,
                      onSubmitted: (_) => _addBayanLang(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addBayanLang,
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilitiesGrid(Color accent, Color textColor) {
    final facilityOptions = [
      {'key': 'wudu_area', 'label': 'Wudu Area'},
      {'key': 'parking', 'label': 'Parking'},
      {'key': 'women_area', 'label': 'Women Area'},
      {'key': 'disability_access', 'label': 'Disability Access'},
      {'key': 'library', 'label': 'Library'},
      {'key': 'madrassa', 'label': 'Madrassa'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facilityOptions.map((f) {
        final key = f['key']!;
        final isSelected = _facilities[key] ?? false;
        return FilterChip(
          label: Text(f['label']!),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              _facilities[key] = val;
            });
          },
          selectedColor: accent.withValues(alpha: 0.2),
          checkmarkColor: accent,
          labelStyle: TextStyle(
            color: isSelected ? accent : textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: isSelected ? accent : textColor.withValues(alpha: 0.2),
          ),
        );
      }).toList(),
    );
  }

  void _addBayanLang() {
    final lang = _bayanController.text.trim();
    if (lang.isNotEmpty && !_bayanLangs.contains(lang)) {
      setState(() {
        _bayanLangs.add(lang);
        _bayanController.clear();
      });
    }
  }

  Widget _buildBayanLangsEditor(Color accent, Color textColor, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bayanLangs.map((l) {
        return Chip(
          label: Text(l),
          onDeleted: () {
            setState(() {
              _bayanLangs.remove(l);
            });
          },
          deleteIcon: const Icon(Icons.close, size: 14),
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: textColor, fontSize: 12),
          side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
        );
      }).toList(),
    );
  }
}
