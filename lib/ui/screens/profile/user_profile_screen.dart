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
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isEditing = false;
  Map<String, dynamic>? _profileExtraData;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.currentUser.name);
    _phoneCtrl = TextEditingController(text: auth.currentUser.phone);
    _emailCtrl = TextEditingController(text: auth.currentUser.email);
    _addressCtrl = TextEditingController(text: auth.currentUser.address ?? '');
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
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

  Future<bool> _saveProfileDetails() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _isSaving = true);

    final cleanPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final last10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateUserProfile(
      name: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : auth.currentUser.name,
      phone: last10,
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
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile details.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }
    }
    return ok;
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
                                  const SizedBox(height: 6),
                                  Text(
                                    user.role.nameString,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.person_outline_rounded,
                                              color: AppColors.primary,
                                              size: 20),
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
                                      if (!_isEditing)
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 15),
                                          label: const Text(
                                            'Edit',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(
                                                color: AppColors.primary),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: () {
                                            setState(() => _isEditing = true);
                                          },
                                        )

                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Mobile Number (Editable when _isEditing)
                                  MandatoryLabel('Mobile Number',
                                      isRequired: _isEditing),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    readOnly: !_isEditing,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'Enter 10-digit mobile number',
                                      prefixIcon: const Icon(
                                          Icons.phone_android_rounded,
                                          size: 20),
                                      suffixIcon: _isEditing
                                          ? (_phoneCtrl.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear,
                                                      size: 18),
                                                  onPressed: () => setState(
                                                      () => _phoneCtrl.clear()),
                                                )
                                              : null)
                                          : (user.phone.isNotEmpty
                                              ? const Tooltip(
                                                  message: 'Verified Mobile',
                                                  child: Icon(
                                                      Icons.verified_rounded,
                                                      size: 18,
                                                      color: Colors.green),
                                                )
                                              : null),
                                      filled: !_isEditing,
                                      fillColor: !_isEditing
                                          ? (isDark
                                              ? Colors.grey.shade900
                                              : const Color(0xFFF8FAFC))
                                          : null,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Mobile number is required';
                                      }
                                      final clean =
                                          v.replaceAll(RegExp(r'\D'), '');
                                      if (clean.length != 10 ||
                                          !RegExp(r'^[6-9]\d{9}$')
                                              .hasMatch(clean)) {
                                        return 'Please enter a valid 10-digit mobile number';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // Email Address
                                  const MandatoryLabel('Email Address',
                                      isRequired: false),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    readOnly: !_isEditing,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      prefixIcon: const Icon(
                                          Icons.email_outlined,
                                          size: 20),
                                      filled: !_isEditing,
                                      fillColor: !_isEditing
                                          ? (isDark
                                              ? Colors.grey.shade900
                                              : const Color(0xFFF8FAFC))
                                          : null,
                                    ),
                                    validator: (v) {
                                      if (v != null && v.trim().isNotEmpty) {
                                        final emailRegex = RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                        if (!emailRegex.hasMatch(v.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // Address
                                  const MandatoryLabel('Address / Location',
                                      isRequired: false),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _addressCtrl,
                                    readOnly: !_isEditing,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter resident or street address',
                                      prefixIcon: const Icon(
                                          Icons.home_outlined,
                                          size: 20),
                                      filled: !_isEditing,
                                      fillColor: !_isEditing
                                          ? (isDark
                                              ? Colors.grey.shade900
                                              : const Color(0xFFF8FAFC))
                                          : null,
                                    ),
                                  ),

                                  // Save Button - Only displayed when editing
                                  if (_isEditing) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _isSaving
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _isEditing = false;
                                                      _nameCtrl.text =
                                                          user.name;
                                                      _phoneCtrl.text =
                                                          user.phone;
                                                      _emailCtrl.text =
                                                          user.email;
                                                      _addressCtrl.text =
                                                          user.address ?? '';
                                                    });
                                                  },
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            icon: _isSaving
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white),
                                                  )
                                                : const Icon(
                                                    Icons.check_circle_outline,
                                                    size: 18),
                                            label: Text(_isSaving
                                                ? 'Saving Details...'
                                                : 'Save'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: _isSaving
                                                ? null
                                                : () async {
                                                    final ok =
                                                        await _saveProfileDetails();
                                                    if (ok && mounted) {
                                                      setState(() =>
                                                          _isEditing = false);
                                                    }
                                                  },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
}

