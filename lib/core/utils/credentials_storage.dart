import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SavedLoginAccount {
  final String username;
  final String password;
  final DateTime lastUsedAt;

  const SavedLoginAccount({
    required this.username,
    required this.password,
    required this.lastUsedAt,
  });

  factory SavedLoginAccount.fromJson(Map<String, dynamic> json) {
    return SavedLoginAccount(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      lastUsedAt:
          DateTime.tryParse(json['last_used_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }
}

/// Credentials storage service for managing saved login credentials.
class CredentialsStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrateLegacyCredentialsIfNeeded();
  }

  static Future<void> saveRememberedAccount(
    String username,
    String password,
  ) async {
    await init();

    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) return;

    final accounts = getSavedAccounts();
    final updatedAccounts =
        accounts
            .where(
              (account) =>
                  account.username.toLowerCase() !=
                  normalizedUsername.toLowerCase(),
            )
            .toList()
          ..insert(
            0,
            SavedLoginAccount(
              username: normalizedUsername,
              password: password,
              lastUsedAt: DateTime.now(),
            ),
          );

    await _prefs!.setString(
      AppConstants.savedAccountsKey,
      jsonEncode(updatedAccounts.map((account) => account.toJson()).toList()),
    );
    await _prefs!.setString(AppConstants.savedEmailKey, normalizedUsername);
    await _prefs!.setString(AppConstants.savedPasswordKey, password);
    await _prefs!.setBool(AppConstants.rememberMeKey, updatedAccounts.isNotEmpty);
  }

  static Future<void> removeAccount(String username) async {
    await init();

    final updatedAccounts =
        getSavedAccounts()
            .where(
              (account) =>
                  account.username.toLowerCase() != username.trim().toLowerCase(),
            )
            .toList();

    await _prefs!.setString(
      AppConstants.savedAccountsKey,
      jsonEncode(updatedAccounts.map((account) => account.toJson()).toList()),
    );

    if (updatedAccounts.isEmpty) {
      await _prefs!.remove(AppConstants.savedEmailKey);
      await _prefs!.remove(AppConstants.savedPasswordKey);
      await _prefs!.setBool(AppConstants.rememberMeKey, false);
      return;
    }

    await _prefs!.setString(
      AppConstants.savedEmailKey,
      updatedAccounts.first.username,
    );
    await _prefs!.setString(
      AppConstants.savedPasswordKey,
      updatedAccounts.first.password,
    );
    await _prefs!.setBool(AppConstants.rememberMeKey, true);
  }

  static List<SavedLoginAccount> getSavedAccounts() {
    if (_prefs == null) return const [];

    final raw = _prefs!.getString(AppConstants.savedAccountsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final accounts =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(SavedLoginAccount.fromJson)
              .where((account) => account.username.isNotEmpty)
              .toList()
            ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return accounts;
    } catch (_) {
      return const [];
    }
  }

  static SavedLoginAccount? getMostRecentAccount() {
    final accounts = getSavedAccounts();
    if (accounts.isEmpty) return null;
    return accounts.first;
  }

  static String? getSavedEmail() {
    return getMostRecentAccount()?.username;
  }

  static String? getSavedPassword() {
    return getMostRecentAccount()?.password;
  }

  static bool isRememberMeEnabled() {
    if (_prefs == null) return false;
    return getSavedAccounts().isNotEmpty;
  }

  static Future<bool> clearCredentials() async {
    await init();
    final accountsRemoved = await _prefs!.remove(AppConstants.savedAccountsKey);
    final emailRemoved = await _prefs!.remove(AppConstants.savedEmailKey);
    final passwordRemoved = await _prefs!.remove(AppConstants.savedPasswordKey);
    await _prefs!.setBool(AppConstants.rememberMeKey, false);
    return accountsRemoved || emailRemoved || passwordRemoved;
  }

  static Future<Map<String, String?>?> getSavedCredentials() async {
    await init();
    final account = getMostRecentAccount();
    if (account == null) {
      return null;
    }
    return {
      'email': account.username,
      'password': account.password,
    };
  }

  static Future<void> _migrateLegacyCredentialsIfNeeded() async {
    if (_prefs == null) return;

    final hasNewAccounts =
        (_prefs!.getString(AppConstants.savedAccountsKey) ?? '').isNotEmpty;
    final rememberEnabled = _prefs!.getBool(AppConstants.rememberMeKey) ?? false;

    if (hasNewAccounts || !rememberEnabled) {
      return;
    }

    final legacyEmail = _prefs!.getString(AppConstants.savedEmailKey);
    final legacyPassword = _prefs!.getString(AppConstants.savedPasswordKey);
    if (legacyEmail == null ||
        legacyEmail.isEmpty ||
        legacyPassword == null ||
        legacyPassword.isEmpty) {
      return;
    }

    final migratedAccount = SavedLoginAccount(
      username: legacyEmail,
      password: legacyPassword,
      lastUsedAt: DateTime.now(),
    );

    await _prefs!.setString(
      AppConstants.savedAccountsKey,
      jsonEncode([migratedAccount.toJson()]),
    );
  }
}
