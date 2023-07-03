import 'dart:async';
import 'dart:convert';

import 'package:genos_dart/genos_dart.dart';
import 'package:genos_dart/src/model/event_sink.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Genos {
  static String _gHost = gLocalhost;
  static String _gPort = gPort;
  static late int _tour;
  static late DBMS _dbms;
  static late String _connectionId;
  static String _unsecureGPort = '80';
  static String _privateDirectory = '';
  static String _encryptionKey = '';
  static late final String _appSignature;
  static late final String _appWsSignature;
  static late final Auth auth;
  static bool _initialized = false;
  late Function(Genos) _onInitialization;
  late Function()? _onLoginOut;
  late Function(Map<String, String>) _onConfigChanged;

  static final Genos _instance = Genos._();

  Genos._();

  ///Initialize geno client
  ///[host] the remote host which run the http server
  ///[port] the ssl supported port on which the server is running
  ///[unsecurePort] the none ssl supported port on which the server is running,
  /// default to 80
  ///[appSignature] the signature to send to the server for authentication
  ///[appWsSignature] the ws signature to send to the server for authentication
  ///[appPrivateDirectory] is the directory where the app should store cache files
  ///[onInitialization] is called when geno components are all set up
  ///[onConfigChanged] is called when the [host], [port] or [unsecurePort] have
  ///changed
  ///[onUserLoggedOut] is called when the user logged out
  Future<void> initialize({
    String host = gLocalhost,
    String port = gPort,
    String unsecurePort = '80',
    required String encryptionKey,
    required String appSignature,
    required String appWsSignature,
    required String appPrivateDirectory,
    required Future Function(Genos) onInitialization,
    Function()? onUserLoggedOut,
    DBMS dbms = DBMS.mysql,
    int tour = 3,
    Function(Map<String, String>)? onConfigChanged,
  }) async {
    _onInitialization = onInitialization;
    if (!_initialized) {
      _connectionId = Uuid().v1();
      _tour = tour;
      _privateDirectory = appPrivateDirectory;
      _encryptionKey = encryptionKey;
      _appSignature = appSignature;
      _appWsSignature = appWsSignature;
      _onLoginOut = onUserLoggedOut;
      auth = await Auth.instance;
      _dbms = dbms;
      GDirectRequest.dbType = dbms;
      auth.addLoginListener(_onUserLoggedOut);

      _gHost = host;
      _gPort = port;
      _unsecureGPort = unsecurePort;

      _onConfigChanged = onConfigChanged ?? (d) {};
      _onInitialization(this);
      _initialized = true;
    }
  }

  void _onUserLoggedOut(bool value) {
    if (!value) {
      _onLoginOut?.call();
    }
  }

  ///Change the configurations relative to remote server
  Future changeConfig(
      {String? host, String? port, String? unsecurePort}) async {
    if (host != null) {
      _gHost = host;
    }
    if (port != null && port != _gPort) {
      _gPort = port;
    }
    if (unsecurePort != null && unsecurePort != _unsecureGPort) {
      _unsecureGPort = unsecurePort;
    }
    _onConfigChanged(
        {'host': _gHost, 'port': _gPort, 'unsecurePort': _unsecureGPort});

  }

  static DBMS get dbms => _dbms;

  static Genos get instance => _instance;
  static int get tour => _tour;
  static String get encryptionKey => _encryptionKey;
  static String get appSignature =>
      Auth.encodeBase64String(_appSignature, _tour);

  static String get appWsSignature =>
      Auth.encodeBase64String(_appWsSignature, _tour);

  static String get appPrivateDirectory => _privateDirectory;
  static String get connectionId => _connectionId;
  static String get baseUrl => 'https://$_gHost:$_gPort/';
  static String get unsecureBaseUrl => 'http://$_gHost:$_unsecureGPort/';
  static String get wsBaseUrl => 'wss://$_gHost:$_gPort/ws/';
  static String get unSecureWsBaseUrl => 'ws://$_gHost:$_unsecureGPort/ws/';
  static String getEmailSigningUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/email/signing'
        : '$unsecureBaseUrl' 'auth/email/signing';
  }

  static String get qrLoginRoute => 'auth/qr_code/listen';

  static String getEmailLoginUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/email/login'
        : '$unsecureBaseUrl' 'auth/email/login';
  }

  static String getEmailChangeUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/email/change'
        : '$unsecureBaseUrl' 'auth/email/change';
  }

  static String getQRConfirmationUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/qr_code/confirmation'
        : '$unsecureBaseUrl' 'auth/qr_code/confirmation';
  }

  static String getPasswordRecoveryUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/email/password/recovering'
        : '$unsecureBaseUrl' 'auth/email/password/recovering';
  }

  static String getChangePasswordUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/email/password/change'
        : '$unsecureBaseUrl' 'auth/email/password/change';
  }

  static String getPhoneAuthUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/phone' : '$unsecureBaseUrl' 'auth/phone';
  }

  static String getPhoneChangeUrl([bool secured = true]) {
    return secured
        ? '$baseUrl' 'auth/phone/change'
        : '$unsecureBaseUrl' 'auth/phone/change';
  }

  static String getSubscriptionUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'subscribe' : '$unsecureBaseUrl' 'subscribe';
  }

  static String getPointImageUploadUrl(
      {required String pointId, bool secured = true}) {
    return secured
        ? '$baseUrl' 'upload/$pointId/$gImage/'
        : '$unsecureBaseUrl' 'upload/$pointId/$gImage/';
  }

  static String getPointMediathecUploadUrl(
      {required String pointId, bool secured = true}) {
    return secured
        ? '$baseUrl' 'upload/$pointId/$gMediathec/'
        : '$unsecureBaseUrl' 'upload/$pointId/$gMediathec/';
  }

  static DateTime get genosDateTime =>
      DataListener.lastKnownSeverDate ??
          Result.serverDateTime ??
          DateTime.now();

  ///The host which runs the http server
  String get host => _gHost;

  ///The port of the http server
  String get port => _gPort;

  static Future<void> subscribeUser({
    required Function(String) onSuccess,
    required Function(String) onError,
    required Map<String, dynamic> data,
    bool secure = true,
  }) async {
    final url =
    Uri.parse('${secure ? Genos.baseUrl : Genos.unsecureBaseUrl}subscribe');

    try {
      final response = await http.post(url,
          headers: {
            'Content-type': 'application/json',
            //'origin': 'http://localhost'
          },
          body: json.encode(data));

      if (response.statusCode == 200) {
        onSuccess(response.body.toString());
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  static Future<void> deleteObject({
    required String path,
    required Function() onSuccess,
    required Function(String) onError,
    Map<String, String> headers = const {},
    bool secure = true,
  }) async {
    final url =
    Uri.parse('${secure ? Genos.baseUrl : Genos.unsecureBaseUrl}$path');

    try {
      final response = await http.delete(url,
          headers: {gAppSignature: Genos.appSignature}..addAll(headers),
          body: "");

      if (response.statusCode == 200) {
        onSuccess();
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}

enum DBMS {
  postgres,
  mysql;

  @override
  String toString() {
    switch(this) {
      case DBMS.postgres:
        return 'Postgres';
      case DBMS.mysql:
        return 'Mysql';
    }
  }
}

///Turn a String return by genos uploadTask to usable link
///[source] is the string to transform
///[secure] tells if the link should use https protocol or http.
///     Default to true so https is used
String linkify(String source, {bool secure = true}) {
  return '${secure ? Genos.baseUrl : Genos.unsecureBaseUrl}$source';
}

///  DataListener tableListener = TableListener(table: 'student');
///     tableListener.listen(() {
///       print('Change HAPPENED ON TABLE student');
///     });
///
///  DataListener rowListener = DataListener(table: 'student', rowId: "2");
///     tableListener.listen(() {
///       print('Change HAPPENED ON TABLE student');
///     });
///
class DataListener {
  late WebSocketChannel _webSocket;

  bool _closeByClient = false;
  String table;
  String? tag;
  late int _reconnectionDelay;

  static DateTime? _lastKnownServerDate;

  DataListener({required this.table, this.tag});

  static DateTime? get lastKnownSeverDate => _lastKnownServerDate;

  void listen(
      void Function(DataChange) onChanged, {
        int reconnectionDelay = 1000,
        bool secure = true,
        bool refresh = false,
        bool reflexive = false,
        void Function(String)? onError,
        void Function()? onDispose,
      }) {
    _reconnectionDelay = reconnectionDelay;
    _create(onChanged, secure, onError, onDispose, refresh, reflexive);
  }

  void _create(
      void Function(DataChange) onChanged,
      bool secure,
      void Function(String)? onError,
      void Function()? onDispose,
      bool refresh,
      bool reflexive) {
    _webSocket = createChannel('db/listen', secure);
    _webSocket.sink.add(_toJson());
    _webSocket.stream.listen((event) {
      DataEventSink eventSink = DataEventSink.fromJson(event);
      //We store the server datetime
      _lastKnownServerDate = eventSink.dateTime;
      //The connection have be close by the server due to duplicate listening
      if (eventSink.event == 'close' || eventSink.event == 'unauthenticated') {
        dispose();
        onDispose?.call();
        //The connection have been closed due to connection issue
        //At this point, change can be made on the database during
        //the reconnection phase so we call [onChanged] to make user
        //do something once the connection is reestablished
      } else if (eventSink.event == 'registered') {
        if (refresh) {
          onChanged(DataChange(
              changeType: ChangeType.none,
              connectionId: eventSink.connectionId,
              tag: eventSink.tag,
              table: eventSink.table));
        }
        //Change happens on the database
      } else {
        //we notify him
        if (reflexive || eventSink.connectionId != Genos.connectionId) {
          onChanged(DataChange(
              changeType: ChangeType.fromString(eventSink.event),
              connectionId: eventSink.connectionId,
              tag: eventSink.tag,
              table: eventSink.table));
          //the change is made by this client. We notify him because the
          //change subscription is reflexive
        }
      }
    }, onError: (e) {
      onError?.call(e.toString());
    }).onDone(() {
      if (!_closeByClient) {
        Timer(Duration(milliseconds: _reconnectionDelay), () {
          _create(onChanged, secure, onError, onDispose, true, reflexive);
        });
      }
    });
  }

  String _toJson() {
    return jsonEncode({
      gAppWsKey: Genos.appWsSignature,
      gConnectionId: Genos.connectionId,
      gTable: table,
      gTag: tag,
    });
  }

  String get key => tag == null ? table : '$table/$tag';

  //Dispose the listener
  void dispose() {
    _closeByClient = true;
    _webSocket.sink.close();
  }
}

class SingleListener {
  late WebSocketChannel _webSocket;

  bool _closeByClient = false;
  //List<String> tables;
  Map<String, List<String>> tags = {};
  late int _reconnectionDelay;

  static DateTime? _lastKnownServerDate;

  SingleListener({required this.tags});

  static DateTime? get lastKnownSeverDate => _lastKnownServerDate;

  void listen(
      void Function(DataChange) onChanged, {
        int reconnectionDelay = 1000,
        bool secure = true,
        bool refresh = false,
        bool reflexive = false,
        void Function(String)? onError,
        void Function()? onDispose,
      }) {
    _reconnectionDelay = reconnectionDelay;
    _create(onChanged, secure, onError, onDispose, refresh, reflexive);
  }

  void _create(
      void Function(DataChange) onChanged,
      bool secure,
      void Function(String)? onError,
      void Function()? onDispose,
      bool refresh,
      bool reflexive) {
    if (tags.isNotEmpty) {
      _webSocket = createChannel('db/single/listen', secure);
      _webSocket.sink.add(_toJson());
      _webSocket.stream.listen((event) {
        DataEventSink eventSink = DataEventSink.fromJson(event);
        //We store the server datetime
        _lastKnownServerDate = eventSink.dateTime;
        //The connection have be close by the server due to duplicate listening
        if (eventSink.event == 'close') {
          dispose();
          onDispose?.call();
          //The connection have been closed due to connection issue
          //At this level, change can be made on the database during
          //the reconnection phase so we call [onChanged] to make user
          //do something once the connection is reestablished
        } else if (eventSink.event == 'registered') {
          if (refresh) {
            onChanged(DataChange(
                changeType: ChangeType.none,
                connectionId: eventSink.connectionId,
                tag: eventSink.tag,
                table: eventSink.table));
          }
          //Change happens on the database
        } else {
          //we notify him
          if (reflexive || eventSink.connectionId != Genos.connectionId) {
            onChanged(DataChange(
                changeType: ChangeType.fromString(eventSink.event),
                connectionId: eventSink.connectionId,
                tag: eventSink.tag,
                table: eventSink.table));
            //the change is made by this client. We notify him because the
            //change subscription is reflexive
          }
        }
      }, onError: (e) {
        onError?.call(e.toString());
      }).onDone(() {
        if (!_closeByClient) {
          Timer(Duration(milliseconds: _reconnectionDelay), () {
            _create(onChanged, secure, onError, onDispose, true, reflexive);
          });
        }
      });
    }
  }

  void addSource(SingleLowLevelDataListener listener) {
    bool shouldSink = false;
    if (!tags.keys.contains(listener.table)) {
      shouldSink = true;
      tags[listener.table] = [listener.tagsValue];
      // if(listener.key != null && listener.key!.trim().isNotEmpty) {
      //   tags ??= {};
      //   tags![listener.table] = [listener.key!];
      // }
    } else if (!tags[listener.table]!.contains(listener.tagsValue)) {
      tags[listener.table]!.add(listener.tagsValue);
      shouldSink = true;
    }

    if (shouldSink) {
      _webSocket.sink.add(_toJson(update: true));
    }
  }

  void deleteSource(SingleLowLevelDataListener listener) {
    if (tags.isNotEmpty) {
      if (tags[listener.table] != null &&
          tags[listener.table]!.contains(listener.tagsValue)) {
        tags[listener.table]!
            .removeWhere((element) => element == listener.tagsValue);
        if (tags[listener.table]!.isEmpty) {
          tags.remove(listener.table);
          if (tags.isEmpty) {
            //No element provided so we dispose the listener
            dispose();
          } else {
            _webSocket.sink.add(_toJson(update: true));
          }
        }
      }
    }
  }

  String _toJson({bool? update}) {
    return jsonEncode({
      gAppWsKey: Genos.appWsSignature,
      gConnectionId: Genos.connectionId,
      gTags: tags,
      gUpdate: update,
    });
  }

  static String tagFromList(List<String> tags, {String pattern = '/'}) {
    return tags.toSplitableString(pattern);
  }

  //Dispose the listener
  void dispose() {
    _closeByClient = true;
    tags.clear();
    _webSocket.sink.close();
  }
}

class DataChange {
  final ChangeType changeType;
  final String? table;
  final String? tag;
  final String? connectionId;

  DataChange({
    required this.changeType,
    required this.connectionId,
    required this.table,
    required this.tag,
  });
}

enum ChangeType {
  insert,
  update,
  delete,
  none,
  unknown;

  static ChangeType fromString(String value) {
    switch (value) {
      case 'insert':
        return ChangeType.insert;
      case 'update':
        return ChangeType.update;
      case 'delete':
        return ChangeType.delete;
      case 'registered':
        return ChangeType.none;
      default:
        return ChangeType.unknown;
    }
  }
}

WebSocketChannel createChannel(String url, [bool secure = true]) {
  return WebSocketChannel.connect(Uri.parse(
      '${secure ? Genos.wsBaseUrl : Genos.unSecureWsBaseUrl}' '$url'));
}

// an example of use.
// we want to get all user with 3 as id
//GDirectRequest.select(
//         sql: 'SELECT * FROM student WHERE id = ? ',
//         values: [3]
//    ).exec(
//         onSuccess: (results) {
//           results.data.forEach((element) {
//             print(element);
//
//           });
//         }, onError: (error) {
//           print(error);
//     });
class GDirectRequest {
  String? connectionId;
  String sql;
  GRequestType type;
  String table;
  static late DBMS dbType;
  bool dateTimeValueEnabled;
  dynamic values;

  GDirectRequest({
    required this.sql,
    required this.type,
    required this.table,
    this.connectionId,
    this.values,
    this.dateTimeValueEnabled = false,
  });

  ///[dateTimeValueEnabled] inform genos that the query will contain Timestamp values
  factory GDirectRequest.select({
    required String sql,
    dynamic values,
    bool dateTimeValueEnabled = true,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.select,
        dateTimeValueEnabled: dateTimeValueEnabled,
        table: '',
        values: values);
  }

  factory GDirectRequest.insert({
    required String table,
    required String sql,
    dynamic values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.insert,
        table: table,
        values: values);
  }

  factory GDirectRequest.fluentInsert(
      {required String table, required FluentObject object}) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: "INSERT INTO $table "
            "(${object.toFluentMap().keyWithComma}) "
            "VALUES (${object.toFluentMap().valuesAsQuestionMarks})",
        type: GRequestType.insert,
        table: table,
        values: [...object.toFluentMap().values]);
  }

  factory GDirectRequest.insertMap(
      {required String table, required Map<String, dynamic> map}) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: "INSERT INTO $table "
            "(${map.keyWithComma}) "
            "VALUES (${map.valuesAsQuestionMarks})",
        type: GRequestType.insert,
        table: table,
        values: [...map.values]);
  }

  factory GDirectRequest.update({
    required String table,
    required String sql,
    dynamic values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.update,
        table: table,
        values: values);
  }

  factory GDirectRequest.delete({
    required String table,
    required String sql,
    dynamic values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.delete,
        table: table,
        values: values);
  }

  factory GDirectRequest.create({
    required String table,
    required String sql,
    dynamic values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.create,
        table: table,
        values: values);
  }

  factory GDirectRequest.drop({
    required String table,
    required String sql,
    dynamic values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.drop,
        table: table,
        values: values);
  }

  String _toJson() {
    return jsonEncode({
      gAppSignature: Genos.appSignature,
      gConnectionId: connectionId,
      gTable: table,
      gDateTimeEnable: dateTimeValueEnabled,
      gType: type.toString(),
      gValues: values,
      gDbType: dbType.toString(),
      gSql: sql,
    });
  }

  Future<void> exec({
    required Function(Result) onSuccess,
    required Function(RequestError) onError,
    bool secure = true,
  }) async {
    final url =
    Uri.parse('${secure ? Genos.baseUrl : Genos.unsecureBaseUrl}request');

    try {
      final response = await http.post(url,
          headers: {
            'Content-type': 'application/json',
            //'origin': 'http://localhost'
          },
          body: _toJson());

      if (response.statusCode == 200) {
        Result result = Result.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.error!);
        } else {
          onSuccess(result);
        }
      } else {
        onError(RequestError(message: response.body.toString(), code: 200));
      }
    } catch (e) {
      onError(RequestError(message: e.toString(), code: 400));
    }
  }
}

enum GRequestType {
  select,
  update,
  insert,
  create,
  drop,
  delete;

  @override
  String toString() {
    switch (this) {
      case GRequestType.select:
        return 'select';
      case GRequestType.update:
        return 'update';
      case GRequestType.insert:
        return 'insert';
      case GRequestType.delete:
        return 'delete';
      case GRequestType.create:
        return 'create';
      case GRequestType.drop:
        return 'drop';
    }
  }
}

extension MapExt on Map<String, dynamic> {
  String get valuesAsQuestionMarks {
    String r = '';
    if (length > 0) {
      r = '?';
      int i = 0;
      forEach((key, value) {
        if (i != 0) {
          r = '$r, ?';
        } else {
          i++;
        }
      });
    }
    return r;
  }

  String get keyWithEqualAndQuestionMarks {
    String str = '';
    List<String> l = [];
    l.addAll(keys);
    if (l.isNotEmpty) {
      str = '${l[0]} = ?';
      for (int i = 1; i < l.length; i++) {
        str = '$str, \n${l[i]} = ?';
      }
    }
    return '$str ';
  }

  String get keyWithComma {
    String str = '';
    List<String> l = [];
    l.addAll(keys);
    if (l.isNotEmpty) {
      str = l[0];
      for (int i = 1; i < l.length; i++) {
        str = '$str, \n${l[i]}';
      }
    }
    return '$str ';
  }
}

const String gInterruptionError =
    'Connection closed before full header was received';
const String unavailableHostError = 'Connection refused';
const String hostLookUpError = 'Failed host lookup';
