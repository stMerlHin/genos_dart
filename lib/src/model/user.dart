import 'dart:convert';

import '../utils/constants.dart';


class User {

  final String? email;
  final String? phoneNumber;
  final String? uid;
  final String? password;
  final String? appLocation;
  final AuthenticationMode mode;

  const User({
    this.email,
    this.phoneNumber,
    this.appLocation,
    this.uid,
    this.password,
    this.mode = AuthenticationMode.none,
  });

  String toJson() {
    return jsonEncode(toMap());
  }

  String toNullablePasswordJson() {
    return jsonEncode(toNullablePasswordMap());
  }

  Map<String, dynamic> toMap() {
    return {
      gUserEmail: email,
      gUserPassword: password,
      gAppLocalisation: appLocation,
      gUserUId: uid,
      gUserAuthMode: mode.toString(),
      gUserPhoneNumber: phoneNumber,
    };
  }

  Map<String, dynamic> toNullablePasswordMap() {
    return {
      gUserEmail: email,
      gUserPassword: null,
      gAppLocalisation: appLocation,
      gUserUId: uid,
      gUserAuthMode: mode.toString(),
      gUserPhoneNumber: phoneNumber,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map[gUserEmail],
      password: map[gUserPassword],
      uid: map[gUserUId],
      appLocation: map[gAppLocalisation],
      phoneNumber: map[gUserPhoneNumber],
      mode: AuthenticationMode.parse(map[gUserAuthMode]),
    );
  }

  factory User.fromJson(String data) {
    Map<String, dynamic> map = jsonDecode(data);
    return User(
      email: map[gUserEmail],
      password: map[gUserPassword],
      uid: map[gUserUId],
      appLocation: map[gAppLocalisation],
      phoneNumber: map[gUserPhoneNumber],
      mode: AuthenticationMode.parse(map[gUserAuthMode]),
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