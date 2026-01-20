import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_text_field.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_service.dart';
import 'package:munajat_e_maqbool_app/services/masjid_image_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_location_picker.dart';

class MasjidRegistrationScreen extends StatefulWidget {
  const MasjidRegistrationScreen({super.key});

  @override
  State<MasjidRegistrationScreen> createState() =>
      _MasjidRegistrationScreenState();
}

class _MasjidRegistrationScreenState extends State<MasjidRegistrationScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  double? _lat;
  double? _lng;
  File? _logo;

  final MasjidService _masjidService = MasjidService();
  final MasjidImageService _imageService = MasjidImageService();

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

  Future<void> _pickLogo() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) {
      setState(() => _logo = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select masjid location on map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final masjidId = await _masjidService.registerMasjid({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'contact_number': _contactPhoneController.text.trim(),
        'lat': _lat,
        'long': _lng,
      });

      if (masjidId != null && _logo != null) {
        await _imageService.uploadAndSaveImage(
          file: _logo!,
          masjidId: masjidId,
          imageType: 'logo',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Masjid registered successfully! Waiting for approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register masjid: $e')),
        );
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
      title: 'Register New Masjid',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: _logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(_logo!, fit: BoxFit.cover),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset('assets/icons/icon_masjid.png'),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Masjid Logo',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

              // Location Picker Field
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
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              GlassTextField(
                controller: _descController,
                hintText: 'Description / Instructions',
                icon: Icons.description_rounded,
                isDark: isDark,
                maxLines: 3,
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
                          'Submit for Approval',
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
}
