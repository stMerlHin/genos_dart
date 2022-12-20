import 'dart:async';
import 'dart:convert';

import 'package:genos_dart/genos_dart.dart';
import 'package:genos_dart/src/model/fluent_object.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Genos {
  static String _gHost = gLocalhost;
  static String _gPort = gPort;
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
    Function(Map<String, String>)? onConfigChanged,
  }) async {
    _onInitialization = onInitialization;
    if (!_initialized) {

      _connectionId = Uuid().v1();
      _privateDirectory = appPrivateDirectory;
      _encryptionKey = encryptionKey;
      _appSignature = appSignature;
      _appWsSignature = appWsSignature;
      _onLoginOut = onUserLoggedOut;
      auth = await Auth.instance;
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
    if(!value) {
      _onLoginOut?.call();
    }
  }

  ///Change the configurations relative to remote server
  Future changeConfig({String? host, String? port, String? unsecurePort}) async {
    bool configChanged = false;
    if (host != null && host != _gHost) {
      _gHost = host;
      configChanged = true;
    }
    if (port != null && port != _gPort) {
      _gPort = port;
      configChanged = true;
    }
    if (unsecurePort != null && unsecurePort != _unsecureGPort) {
      _unsecureGPort = unsecurePort;
      configChanged = true;
    }
    if (configChanged) {
      _onConfigChanged({
        'host': _gHost,
        'port': _gPort,
        'unsecurePort': _unsecureGPort });
    }
  }

  static Genos get instance => _instance;
  static String get encryptionKey => _encryptionKey;
  static String get appSignature => _appSignature;
  static String get appWsSignature => _appWsSignature;
  static String get appPrivateDirectory => _privateDirectory;
  static String get connectionId => _connectionId;
  static String get baseUrl => 'https://$_gHost:$_gPort/';
  static String get unsecureBaseUrl => 'http://$_gHost:$_unsecureGPort/';
  static String get wsBaseUrl => 'wss://$_gHost:$_gPort/ws/';
  static String get unSecureWsBaseUrl => 'ws://$_gHost:$_unsecureGPort/ws/';
  static String getEmailSigningUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/email/signing' :
    '$unsecureBaseUrl' 'auth/email/signing';
  }

  static String get qrLoginRoute => 'auth/qr_code/listen';

  static String getEmailLoginUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/email/login' :
    '$unsecureBaseUrl' 'auth/email/login';
  }

  static String getEmailChangeUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/email/change' :
    '$unsecureBaseUrl' 'auth/email/change';
  }

  static String getQRConfirmationUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/qr_code/confirmation' :
    '$unsecureBaseUrl' 'auth/qr_code/confirmation';
  }

  static String getPasswordRecoveryUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/email/password/recovering' :
    '$unsecureBaseUrl' 'auth/email/password/recovering';
  }

  static String getChangePasswordUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/email/password/change' :
    '$unsecureBaseUrl' 'auth/email/password/change';
  }

  static String getPhoneAuthUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/phone' :
    '$unsecureBaseUrl' 'auth/phone';
  }

  static String getPhoneChangeUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'auth/phone/change' :
    '$unsecureBaseUrl' 'auth/phone/change';
  }

  static String getSubscriptionUrl([bool secured = true]) {
    return secured ? '$baseUrl' 'subscribe' :
    '$unsecureBaseUrl' 'subscribe';
  }

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

    final url = Uri.parse('${secure ? Genos.baseUrl :
    Genos.unsecureBaseUrl}subscribe');

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
            //'origin': 'http://localhost'
          },
          body: json.encode(data)
      );

      if (response.statusCode == 200) {
        onSuccess(response.body.toString());
      } else {
        onError(response.body.toString());
      }
    } catch (e)  {
      onError(e.toString());
    }
  }

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

  DataListener({required this.table, this.tag});

  void listen(void Function() onChanged, {int reconnectionDelay = 1000,
    bool secure = true,
    bool refresh = false,
    void Function(String)? onError,
    void Function()? onDispose,
  }) {
    _reconnectionDelay = reconnectionDelay;
    _create(onChanged, secure, onError, onDispose, refresh);
  }

  void _create(void Function() onChanged, bool secure,
      void Function(String)? onError,
      void Function()? onDispose, [bool refresh = false]) {
    _webSocket = createChannel('db/listen', secure);
    _webSocket.sink.add(_toJson());
    _webSocket.stream.listen((event) {
      //The connection have be close by the server due to duplicate
      //listening
      if(event == 'close') {
        dispose();
        onDispose?.call();
        //The connection have be closed due to connection issue
        //At this point, change can be made on the database during
        //the reconnection phase so we call [onChanged] to make user
        //do something once the connection is reestablished
      } else if(event == 'registered') {
        if(refresh) {
          onChanged();
        }
      } else {
        //Change happens on the database
        onChanged();
      }
    }, onError: (e) {
      onError?.call(e.toString());
    }).onDone(() {
      if (!_closeByClient) {
        Timer(Duration(milliseconds: _reconnectionDelay), () {
          _create(onChanged, secure, onError, onDispose, true);
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

  //Dispose the listener
  void dispose() {
    _closeByClient = true;
    _webSocket.sink.close();
  }
}

WebSocketChannel createChannel(String url, [bool secure = true]) {
  return WebSocketChannel.connect(Uri.parse('${secure ? Genos.wsBaseUrl :
  Genos.unSecureWsBaseUrl}' '$url'));
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
  bool dateTimeValueEnabled;
  List<dynamic>? values;

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
    List<dynamic>? values,
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
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: sql,
        type: GRequestType.insert,
        table: table,
        values: values);
  }

  factory GDirectRequest.fluentInsert({
    required String table,
    required FluentObject object
  }) {
    return GDirectRequest(
        connectionId: Genos.connectionId,
        sql: "INSERT INTO $table "
            "(${object.toFluentMap().keyWithComma}) "
            "VALUES (${object.toFluentMap().valuesAsQuestionMarks})",
        type: GRequestType.insert,
        table: table,
        values: [...object.toFluentMap().values]);
  }

  factory GDirectRequest.insertMap({
    required String table,
    required Map<String, dynamic> map
  }) {
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
    List<dynamic>? values,
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
    List<dynamic>? values,
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
    List<dynamic>? values,
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
    List<dynamic>? values,
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
      gSql: sql,
    });
  }

  Future<void> exec({
    required Function(Result) onSuccess,
    required Function(RequestError) onError,
    bool secure = true,
  }) async {

    final url = Uri.parse('${secure ? Genos.baseUrl :
    Genos.unsecureBaseUrl}request');

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
            //'origin': 'http://localhost'
          },
          body: _toJson()
      );

      if (response.statusCode == 200) {
        Result result = Result.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.error!);
        } else {
          onSuccess(result);
        }
      } else {
        onError(
            RequestError(
                message: response.body.toString(),
                code: 200
            )
        );
      }
    } catch (e)  {
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
    if(length > 0) {
      r = '?';
      int i = 0;
      forEach((key, value) {
        if(i != 0) {
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
    if(l.isNotEmpty) {
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
    if(l.isNotEmpty) {
      str = l[0];
      for (int i = 1; i < l.length; i++) {
        str = '$str, \n${l[i]}';
      }
    }
    return '$str ';
  }
}


const String gInterruptionError = 'Connection closed before full header was received';
const String unavailableHostError = 'Connection refused';
const String hostLookUpError = 'Failed host lookup';
