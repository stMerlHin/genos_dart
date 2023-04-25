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

class DataEventSink {
  String event;
  String? connectionId;
  String? table;
  String? tag;
  DateTime dateTime;

  DataEventSink({
    required this.event,
    required this.dateTime,
    required this.connectionId,
    required this.table,
    required this.tag,
  });

  factory DataEventSink.another({
    required String event,
    String? table,
    String? connectionId,
    String? tag,
  }) {
    return DataEventSink(
      event: event,
      dateTime: DateTime.now(),
      connectionId: connectionId,
      table: table,
      tag: tag,
    );
  }

  factory DataEventSink.request({
    required String event,
    required String connectionId,
    String? table,
    String? tag,
  }) {
    return DataEventSink(
      event: event,
      dateTime: DateTime.now(),
      connectionId: connectionId,
      table: table,
      tag: tag,
    );
  }

  factory DataEventSink.fromJson(String source) {
    Map<String, dynamic> map = jsonDecode(source);
    return DataEventSink(
        event: map[gEvent],
        dateTime: DateTime.parse(map[gDateTime]),
        connectionId: map[gConnectionId],
        table: map[gTable],
        tag: map[gTag]);
  }

  Map<String, dynamic> toMap() {
    return {
      gEvent: event,
      gConnectionId: connectionId,
      gTable: table,
      gTag: tag,
      gDateTime: dateTime.toString()
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }
}
