import 'dart:convert';
import 'package:genos_dart/genos_dart.dart';

class RequestError {
  final String message;
  final int code;

  RequestError({
    required this.message,
    this.code = 0,
  });

  factory RequestError.fromMap(Map<String, dynamic> map) {
    return RequestError(
        message: map[gMessage],
        code: map[gCode]
    );
  }

  static RequestError fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return RequestError.fromMap(map);
  }

  String toJson() {
    return jsonEncode({
      gMessage: message,
      gCode: code
    });
  }

  Map<String, dynamic> toMap() {
    return {
      gMessage: message,
      gCode: code
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }

}