import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  TenantProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;
  String? _error;
  String? _localLogoPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _profile = await getIt<TenantRepository>().getProfile();
      _shopNameCtrl.text = _profile!.shopName;
      _ownerNameCtrl.text = _profile!.ownerName;
      _mobileCtrl.text = _profile!.mobile;
      _emailCtrl.text = _profile!.email;
      _addressCtrl.text = _profile!.address ?? '';
      _gstCtrl.text = _profile!.gstNumber ?? '';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() {
      _localLogoPath = file.path;
      _uploadingLogo = true;
    });

    try {
      final logoPath = await getIt<TenantRepository>().uploadLogo(file.path);
      _profile = await getIt<TenantRepository>().getProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded'), backgroundColor: AppColors.success),
        );
      }
      setState(() {
        _localLogoPath = null;
        // keep profile.logoPath
      });
      // ignore unused
      logoPath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _uploadingLogo = false);
  }

  Future<void> _save() async {
    if (_shopNameCtrl.text.trim().isEmpty ||
        _ownerNameCtrl.text.trim().isEmpty ||
        _mobileCtrl.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter ${_businessNameLabel.toLowerCase()}, ${_contactNameLabel.toLowerCase()}, and a 10-digit mobile',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await getIt<TenantRepository>().updateProfile(
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
      );
      _profile = updated;

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final refreshed = authState.user.copyWith(shopName: updated.shopName);
        await getIt<AuthRepository>().updateStoredUser(refreshed);
        if (!mounted) return;
        context.read<AuthBloc>().add(AuthUserUpdated(refreshed));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
      );
      context.go('/settings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('Edit Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildLogoPicker()),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _logoHelpText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GoldDeskTextField(
                        label: '$_businessNameLabel *',
                        hint: _businessNameHint,
                        controller: _shopNameCtrl,
                      ),
                      const SizedBox(height: 12),
                      GoldDeskTextField(
                        label: '$_contactNameLabel *',
                        hint: _contactNameHint,
                        controller: _ownerNameCtrl,
                      ),
                      const SizedBox(height: 12),
                      GoldDeskTextField(
                        label: 'Mobile *',
                        hint: '10-digit number',
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      GoldDeskTextField(
                        label: 'Email',
                        hint: 'Login email',
                        controller: _emailCtrl,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      GoldDeskTextField(
                        label: _addressLabel,
                        hint: _addressHint,
                        controller: _addressCtrl,
                      ),
                      if (!_isKarigar) ...[
                        const SizedBox(height: 12),
                        GoldDeskTextField(
                          label: 'GST Number',
                          hint: 'GST (optional)',
                          controller: _gstCtrl,
                        ),
                      ],
                      const SizedBox(height: 24),
                      GoldDeskButton(
                        text: 'SAVE PROFILE',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLogoPicker() {
    Widget image;
    if (_localLogoPath != null) {
      image = Image.file(File(_localLogoPath!), fit: BoxFit.cover);
    } else if (_profile?.logoPath != null && _profile!.logoPath!.isNotEmpty) {
      image = Image.network(
        '${AppConstants.serverUrl}${_profile!.logoPath}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          _businessIcon,
          size: 40,
          color: AppColors.gold,
        ),
      );
    } else {
      image = Icon(_businessIcon, size: 40, color: AppColors.gold);
    }

    return GestureDetector(
      onTap: _uploadingLogo ? null : _pickLogo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
            child: ClipOval(
              child: SizedBox(width: 96, height: 96, child: image),
            ),
          ),
          if (_uploadingLogo)
            const CircularProgressIndicator(color: AppColors.gold)
          else
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String get _businessType => _profile?.businessType ?? 'Shop';

  bool get _isKarigar => _businessType == 'Karigar';

  String get _businessNameLabel => switch (_businessType) {
    'Showroom' => 'Showroom Name',
    'Karigar' => 'Karigar Name',
    _ => 'Shop Name',
  };

  String get _businessNameHint => switch (_businessType) {
    'Showroom' => 'Your showroom name',
    'Karigar' => 'Your name or workshop name',
    _ => 'Your shop name',
  };

  String get _contactNameLabel => _isKarigar ? 'Contact Name' : 'Owner Name';

  String get _contactNameHint => _isKarigar ? 'Your full name' : 'Owner name';

  String get _addressLabel => _isKarigar ? 'Address' : 'Business Address';

  String get _addressHint => _isKarigar ? 'Your address' : 'Business address';

  String get _logoHelpText => _isKarigar
      ? 'Profile photo or workshop logo'
      : 'Business logo (used on receipts)';

  IconData get _businessIcon => switch (_businessType) {
    'Showroom' => Icons.storefront_outlined,
    'Karigar' => Icons.handyman_outlined,
    _ => Icons.store_outlined,
  };
}
