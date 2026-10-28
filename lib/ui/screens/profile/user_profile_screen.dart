import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/mandatory_label.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _profileExtraData;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.currentUser.name);
    _emailCtrl = TextEditingController(text: auth.currentUser.email);
    _addressCtrl = TextEditingController(text: auth.currentUser.address ?? '');
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    final auth = context.read<AuthProvider>();
    try {
      final res = await ApiService.fetchUserProfile(auth.currentUser.id);
      if (mounted) {
        setState(() {
          _profileExtraData = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final base64Image = await pickProfileImageAsBase64();
      if (base64Image != null && base64Image.isNotEmpty) {
        final auth = context.read<AuthProvider>();
        await auth.updateUserProfile(avatarUrl: base64Image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: AppColors.statusPaid,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateUserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully!'),
            backgroundColor: AppColors.statusPaid,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile details.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(String? avatarUrl, String name, bool isDark) {
    ImageProvider? imageProvider;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64Data = avatarUrl.split(',').last;
          final bytes = base64Decode(base64Data);
          imageProvider = MemoryImage(bytes);
        } catch (_) {}
      } else if (avatarUrl.startsWith('http')) {
        imageProvider = NetworkImage(avatarUrl);
      }
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: isDark
                ? AppColors.darkSurface
                : AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(9),
                child: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions =
        _profileExtraData?['permissions'] as List? ?? auth.permissions;
    final orgName = _profileExtraData?['organization']?['name'] ??
        (user.organizationId != null ? 'Organization Assigned' : 'None');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfileDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Header Profile Banner Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildAvatar(user.avatarUrl, user.name, isDark),
                                  const SizedBox(height: 12),
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.phone,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.verified_user_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          user.role.nameString.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                      ),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        label: Text(
                                          user.isActive
                                              ? 'Active Account'
                                              : 'Inactive',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors.green.withValues(alpha: 0.12),
                                        side: BorderSide(
                                            color: Colors.green.shade300),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. Personal Information Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.person_outline_rounded,
                                          color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Personal Details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Full Name
                                  const MandatoryLabel('Full Name', isRequired: true),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icon(Icons.person_rounded,
                                          size: 20),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Full name is required'
                                            : null,
                                  ),

                                  const SizedBox(height: 14),

                                  // Mobile Number (Read-only)
                                  const MandatoryLabel('Mobile Number (Verified)',
                                      isRequired: false),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    initialValue: user.phone,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.phone_android_rounded,
                                          size: 20),
                                      suffixIcon: const Tooltip(
                                        message: 'Phone number cannot be edited',
                                        child: Icon(Icons.lock_outline_rounded,
                                            size: 18, color: Colors.grey),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.grey.shade900
                                          : const Color(0xFFF1F5F9),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Email Address
                                  const MandatoryLabel('Email Address',
                                      isRequired: false),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your email address',
                                      prefixIcon: Icon(Icons.email_outlined,
                                          size: 20),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Address
                                  const MandatoryLabel('Address / Location',
                                      isRequired: false),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _addressCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter resident or street address',
                                      prefixIcon: Icon(Icons.home_outlined,
                                          size: 20),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Save Profile Details Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: _isSaving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.check_circle_outline,
                                              size: 18),
                                      label: Text(_isSaving
                                          ? 'Saving Details...'
                                          : 'Save Profile Changes'),
                                      onPressed:
                                          _isSaving ? null : _saveProfileDetails,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. Organization & Role Information Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.apartment_rounded,
                                          color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Organization & Hierarchy',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Organization',
                                    orgName,
                                    Icons.business_rounded,
                                    isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    'Assigned Group / Mandal',
                                    user.selectedGroupName ??
                                        (user.groupIds.isNotEmpty
                                            ? 'Group ${user.groupIds.first}'
                                            : 'Not Assigned'),
                                    Icons.groups_rounded,
                                    isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    'System User ID',
                                    user.id,
                                    Icons.fingerprint_rounded,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 4. Permissions Preview Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.vpn_key_rounded,
                                          color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Granted Permissions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  if (permissions.isEmpty)
                                    const Text(
                                      'No custom permissions assigned.',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: permissions.map((p) {
                                        return Chip(
                                          label: Text(
                                            p.toString(),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          backgroundColor: isDark
                                              ? AppColors.darkCardBg
                                              : const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

