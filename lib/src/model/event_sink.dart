import 'dart:convert';

import '../../genos_dart.dart';

class EventSink {
  String event;
  String? connectionId;
  DateTime dateTime;

  EventSink({
    required this.event,
    required this.dateTime,
    required this.connectionId,
  });

  factory EventSink.another({
    required String event,
    String? connectionId,
  }) {
    return EventSink(
        event: event, dateTime: DateTime.now(), connectionId: connectionId);
  }

  factory EventSink.request({
    required String event,
    required String connectionId,
  }) {
    return EventSink(
        event: event, dateTime: DateTime.now(), connectionId: connectionId);
  }

  factory EventSink.fromJson(String source) {
    Map<String, dynamic> map = jsonDecode(source);
    return EventSink(
        event: map[gEvent],
        dateTime: DateTime.parse(map[gDateTime]),
        connectionId: map[gConnectionId]);
  }

  Map<String, dynamic> toMap() {
    return {
      gEvent: event,
      gConnectionId: connectionId,
      gDateTime: dateTime.toString()
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }
}
