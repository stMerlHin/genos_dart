import 'dart:convert';

import 'package:genos_dart/genos_dart.dart';
import 'package:worker_manager/worker_manager.dart';

class Result {
  final List<Map<String, dynamic>> data;
  final bool errorHappened;
  final RequestError? error;
  static DateTime? _serverDateTime;

  Result({this.data = const [], this.errorHappened = false, this.error});

  static Future<Result> fromJson(String json, {bool useIsolate = true}) async {
    Map<String, dynamic> map;
    if(Genos.multiThreadingEnabled && useIsolate) {
      final task = Executor().execute(
          arg1: json,
          fun1: (String js, TypeSendPort port) {
        return jsonDecode(json);
      });
      map = await task.future;
    } else {
      map = jsonDecode(json);
    }

    //get the server dateTime
    Result._serverDateTime = DateTime.parse(map[gDateTime]);

    Map<String, dynamic>? e = map[gError];
    List<Map<String, dynamic>> l = [];
    bool err = map[gErrorHappened];

    map[gData].forEach((element) {
      l.add(element);
    });

    return Result(
        data: l,
        errorHappened: err,
        error: e == null ? null : RequestError.fromMap(e));
  }

  String toJson() {
    return jsonEncode(
        {gData: data, gErrorHappened: errorHappened, gError: error?.toMap()});
  }

  static DateTime? get serverDateTime => _serverDateTime;
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
        errorMessage: map[gError]);
  }

  static AuthResult fromMap(Map<String, dynamic> map) {
    return AuthResult(
        data: map[gData],
        errorHappened: map[gErrorHappened],
        errorMessage: map[gError]);
  }

  String toJson() {
    return jsonEncode(
        {gData: data, gErrorHappened: errorHappened, gError: errorMessage});
  }
}
