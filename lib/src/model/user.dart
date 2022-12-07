import 'dart:convert';

import '../utils/constants.dart';


class User {

  final String? email;
  final String? countryCode;
  final int? phoneNumber;
  final String? uid;
  final String? password;
  final String appLocalization;
  final AuthenticationMode authMode;

  const User({
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.appLocalization = 'fr',
    this.uid,
    this.password,
    this.authMode = AuthenticationMode.none,
  });

  String toJson() {
    return jsonEncode(toMap());
  }

  String toNullPasswordJson() {
    return jsonEncode(toNullPasswordMap());
  }

  Map<String, dynamic> toMap() {
    return {
      gUserEmail: email,
      gUserPassword: password,
      gAppLocalization: appLocalization,
      gUserUId: uid,
      gUserCountryCode: countryCode,
      gUserAuthMode: authMode.toString(),
      gUserPhoneNumber: phoneNumber,
    };
  }

  Map<String, dynamic> toNullPasswordMap() {
    return {
      gUserEmail: email,
      gUserPassword: null,
      gAppLocalization: appLocalization,
      gUserUId: uid,
      gUserCountryCode: countryCode,
      gUserAuthMode: authMode.toString(),
      gUserPhoneNumber: phoneNumber,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map[gUserEmail],
      password: map[gUserPassword],
      uid: map[gUserUId],
      appLocalization: map[gAppLocalization] ?? 'fr',
      countryCode: map[gUserCountryCode],
      phoneNumber: map[gUserPhoneNumber],
      authMode: AuthenticationMode.parse(map[gUserAuthMode]),
    );
  }

  factory User.fromAnother(User user, {
    AuthenticationMode? authMode,
    String? uid,
    String? email,
    String? password,
    String? countryCode,
    int? phoneNumber,
  }) {
    return User(
      email: email ?? user.email,
      countryCode: countryCode ?? user.countryCode,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      appLocalization: user.appLocalization ,
      uid: uid ?? user.uid,
      password: password ?? user.password,
      authMode: authMode ?? user.authMode,
    );
  }
  factory User.fromJson(String data) {
    Map<String, dynamic> map = jsonDecode(data);
    return User(
      email: map[gUserEmail],
      password: map[gUserPassword],
      uid: map[gUserUId],
      appLocalization: map[gAppLocalization],
      phoneNumber: map[gUserPhoneNumber],
      authMode: AuthenticationMode.parse(map[gUserAuthMode]),
    );
  }


  @override
  String toString() {
    return toMap().toString();
  }
}

enum AuthenticationMode {
  email,
  phoneNumber,
  none;

  @override
  String toString() {
    switch(this) {
      case AuthenticationMode.email:
        return 'email';
      case AuthenticationMode.phoneNumber:
        return 'phoneNumber';
      default:
        return 'none';
    }
  }

  static AuthenticationMode parse(String? value) {
    switch(value) {
      case 'email':
        return AuthenticationMode.email;
      case 'phoneNumber':
        return AuthenticationMode.phoneNumber;
      default:
        return AuthenticationMode.none;
    }
  }
}