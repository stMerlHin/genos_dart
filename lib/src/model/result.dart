
import 'dart:convert';

import '../utils/constants.dart';

class Result {
  final List<dynamic> data;
  final bool errorHappened;
  final String error;

  Result({this.data = const [], this.errorHappened = false, this.error = ''});

  static Result fromJson(String json) {
    var map = jsonDecode(json);
    return Result(
        data: map[gData],
        errorHappened: map[gErrorHappened],
        error: map[gErrorMessage]);
  }

  String toJson() {
    return jsonEncode({
      gData: data,
      gErrorHappened: errorHappened,
      gErrorMessage: error
    });
  }
}

class AuthResult {
  final Map<String, dynamic> data;
  final bool errorHappened;
  final String errorMessage;
  final int code;

  AuthResult({
    this.data = const {},
    this.errorHappened = false,
    this.errorMessage = '',
    this.code = -1,
  });

  factory AuthResult.duplicateEntry([String message = 'Email already used']) {
    return AuthResult(
      errorMessage: message,
      errorHappened: true,
      code: 1,
    );
  }

  factory AuthResult.invalidEmail([String message = 'Invalid email.']) {
    return AuthResult(
      errorMessage: message,
      errorHappened: true,
      code: 2,
    );
  }

  static AuthResult fromJson(String json) {
    var map = jsonDecode(json);
    return AuthResult(
        data: map[gData],
        errorHappened: map[gErrorHappened],
        errorMessage: map[gErrorMessage]);
  }


  String toJson() {
    return jsonEncode({
      gData: data,
      gErrorHappened: errorHappened,
      gErrorMessage: errorMessage
    });
  }

}