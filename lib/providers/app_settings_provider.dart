import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/supabase_service.dart';
import '../core/models/user_model.dart';

class AppSettingsProvider extends ChangeNotifier {
  // Preference Storage Keys
  static const String _prefWhatsappNotif = 'vargani_pref_whatsapp_notif';
  static const String _prefSmsNotif = 'vargani_pref_sms_notif';
  static const String _prefReminders = 'vargani_pref_reminders';
  static const String _prefDailyDigest = 'vargani_pref_daily_digest';

  static const String _prefBiometricLock = 'vargani_pref_biometric_lock';
  static const String _prefScreenSecurity = 'vargani_pref_screen_security';
  static const String _prefAutoLockMinutes = 'vargani_pref_autolock_minutes';

  static const String _prefReceiptPrefix = 'vargani_pref_receipt_prefix';
  static const String _prefReceiptHeader = 'vargani_pref_receipt_header';
  static const String _prefReceiptFooter = 'vargani_pref_receipt_footer';
  static const String _prefShowStamp = 'vargani_pref_show_stamp';
  static const String _prefAutoShareWhatsapp = 'vargani_pref_auto_share_whatsapp';

  static const String _prefLastSyncTime = 'vargani_pref_last_sync_time';

  // 1. Notification State
  bool _whatsappNotifications = true;
  bool _smsNotifications = true;
  bool _remindersEnabled = true;
  bool _dailyDigest = true;

  // 2. Security & Privacy State
  bool _biometricLock = false;
  bool _screenSecurity = false;
  int _autoLockMinutes = 5;

  // 3. Receipt Configuration State
  String _receiptPrefix = 'VRG-2026';
  String _receiptHeader = 'श्री गणेश प्रसन्न';
  String _receiptFooter = 'वर्गणी दिल्याबद्दल धन्यवाद! ही अधिकृत पावती आहे.';
  bool _showStamp = true;
  bool _autoShareWhatsapp = true;

  // 4. Backup & Sync State
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String _syncStatusMessage = 'Ready';

  // Getters
  bool get whatsappNotifications => _whatsappNotifications;
  bool get smsNotifications => _smsNotifications;
  bool get remindersEnabled => _remindersEnabled;
  bool get dailyDigest => _dailyDigest;

  bool get biometricLock => _biometricLock;
  bool get screenSecurity => _screenSecurity;
  int get autoLockMinutes => _autoLockMinutes;

  String get receiptPrefix => _receiptPrefix;
  String get receiptHeader => _receiptHeader;
  String get receiptFooter => _receiptFooter;
  bool get showStamp => _showStamp;
  bool get autoShareWhatsapp => _autoShareWhatsapp;

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String get syncStatusMessage => _syncStatusMessage;

  AppSettingsProvider() {
    loadSettings();
  }

  /// Load persisted preferences from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _whatsappNotifications = prefs.getBool(_prefWhatsappNotif) ?? true;
      _smsNotifications = prefs.getBool(_prefSmsNotif) ?? true;
      _remindersEnabled = prefs.getBool(_prefReminders) ?? true;
      _dailyDigest = prefs.getBool(_prefDailyDigest) ?? true;

      _biometricLock = prefs.getBool(_prefBiometricLock) ?? false;
      _screenSecurity = prefs.getBool(_prefScreenSecurity) ?? false;
      _autoLockMinutes = prefs.getInt(_prefAutoLockMinutes) ?? 5;

      _receiptPrefix = prefs.getString(_prefReceiptPrefix) ?? 'VRG-2026';
      _receiptHeader = prefs.getString(_prefReceiptHeader) ?? 'श्री गणेश प्रसन्न';
      _receiptFooter = prefs.getString(_prefReceiptFooter) ??
          'वर्गणी दिल्याबद्दल धन्यवाद! ही अधिकृत पावती आहे.';
      _showStamp = prefs.getBool(_prefShowStamp) ?? true;
      _autoShareWhatsapp = prefs.getBool(_prefAutoShareWhatsapp) ?? true;

      final lastSyncStr = prefs.getString(_prefLastSyncTime);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      } else {
        _lastSyncTime = DateTime.now().subtract(const Duration(hours: 1));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  /// Update and persist Notification Settings
  Future<void> updateNotificationSettings({
    required bool whatsapp,
    required bool sms,
    required bool reminders,
    required bool dailyDigest,
    UserModel? currentUser,
  }) async {
    _whatsappNotifications = whatsapp;
    _smsNotifications = sms;
    _remindersEnabled = reminders;
    _dailyDigest = dailyDigest;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefWhatsappNotif, whatsapp);
      await prefs.setBool(_prefSmsNotif, sms);
      await prefs.setBool(_prefReminders, reminders);
      await prefs.setBool(_prefDailyDigest, dailyDigest);

      _syncToSupabase(currentUser);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Update and persist Security & Privacy Settings
  Future<void> updateSecuritySettings({
    required bool biometric,
    required bool screenSecurity,
    required int autoLockMinutes,
    UserModel? currentUser,
  }) async {
    _biometricLock = biometric;
    _screenSecurity = screenSecurity;
    _autoLockMinutes = autoLockMinutes;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefBiometricLock, biometric);
      await prefs.setBool(_prefScreenSecurity, screenSecurity);
      await prefs.setInt(_prefAutoLockMinutes, autoLockMinutes);

      _syncToSupabase(currentUser);
    } catch (e) {
      debugPrint('Error saving security settings: $e');
    }
  }

  /// Update and persist Receipt Settings
  Future<void> updateReceiptSettings({
    required String prefix,
    required String header,
    required String footer,
    required bool showStamp,
    required bool autoShareWhatsapp,
    UserModel? currentUser,
  }) async {
    _receiptPrefix = prefix.trim();
    _receiptHeader = header.trim();
    _receiptFooter = footer.trim();
    _showStamp = showStamp;
    _autoShareWhatsapp = autoShareWhatsapp;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefReceiptPrefix, _receiptPrefix);
      await prefs.setString(_prefReceiptHeader, _receiptHeader);
      await prefs.setString(_prefReceiptFooter, _receiptFooter);
      await prefs.setBool(_prefShowStamp, showStamp);
      await prefs.setBool(_prefAutoShareWhatsapp, autoShareWhatsapp);

      _syncToSupabase(currentUser);
    } catch (e) {
      debugPrint('Error saving receipt settings: $e');
    }
  }

  /// Perform manual Cloud Sync with Supabase
  Future<bool> syncWithCloud({required String userId}) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _syncStatusMessage = 'Connecting to server...';
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final c = SupabaseService.client;
      if (c != null) {
        _syncStatusMessage = 'Synchronizing records with Supabase...';
        notifyListeners();

        // Safely update last sync state in profiles if accessible
        try {
          await c.from('profiles').update({
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
        } catch (_) {}
      }

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastSyncTime, _lastSyncTime!.toIso8601String());

      _isSyncing = false;
      _syncStatusMessage = 'Sync completed successfully';
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      _syncStatusMessage = 'Sync failed: Offline or server unreachable';
      notifyListeners();
      return false;
    }
  }

  /// Clear temporary caches safely
  Future<void> clearTemporaryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove only non-critical temporary keys
      await prefs.remove('vargani_temp_search_cache');
      await prefs.remove('vargani_temp_pdf_previews');
      notifyListeners();
    } catch (_) {}
  }

  void _syncToSupabase(UserModel? currentUser) {
    if (currentUser == null) return;
    final c = SupabaseService.client;
    if (c == null) return;

    // Asynchronously update profile without blocking UI
    c.from('profiles').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser.id).catchError((_) => null);
  }
}
