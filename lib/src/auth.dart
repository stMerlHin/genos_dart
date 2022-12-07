import 'dart:async';
import 'dart:convert';

import 'package:genos_dart/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'genos_dart_base.dart';
import 'model/result.dart';
import 'model/user.dart';
import 'utils/constants.dart';

class Auth {

  static late final Preferences _preferences;
  static final Auth _instance = Auth._();
  static final List<Function(bool)> _loginListeners = [];
  static User? _user;
  static bool _initialized = false;

  Auth._();

  static void _getAuthenticationData() {
    String? uid = _preferences.getString(gUserUId);
    if(uid != null) {
      String? email = _preferences.getString(gUserEmail);
      String? phoneNumber = _preferences.getString(gUserPhoneNumber);
      String? authMode = _preferences.getString(gUserAuthMode);
      String? password = _preferences.getString(gUserPassword);
      AuthenticationMode mode = AuthenticationMode.parse(authMode);
      if(mode != AuthenticationMode.none) {
        _user = User(
            uid: uid,
            email: email,
            phoneNumber: phoneNumber,
            mode: mode,
            password: password
        );
      }
    }
  }

  void addLoginListener(Function(bool) listener) {
    _loginListeners.add(listener);
  }

  void _notifyLoginListener(bool value) {
    for (var element in _loginListeners) {
      element(value);
    }
  }

  ///Recover the password the password of the user by setting new and
  ///sending email containing the password
  ///[email] the email to which the new password is sent (the user email)
  ///[onSuccess] is called when the password is successfully changed and
  /// sent via email
  ///[onError] is called when the request terminated with an error
  ///[secure] when it set to true use https and http when it's set to false
  Future recoverPassword({
    required String email,
    required Function onSuccess,
    required Function(String) onError,
    bool secure = true,
    String appLocalization = 'fr'
  }) async {
    final url = Uri.parse(Genos.getPasswordRecoveryUrl(secure));
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserEmail: email,
            gAppLocalisation: appLocalization
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.errorMessage);
        } else {
          onSuccess();
        }
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  ///Change the password of the user
  ///[email] The email of the user
  ///[password] the current user password
  ///[newPassword] the new password to use
  ///[onSuccess] is called when the password is successfully updated
  ///  unfortunately detached due to connection issue
  ///[onError] is called when an error occurred
  ///[secure] when it set to true use https and http when it's set to false
  ///[appLocalization] is the localization of the device running the app, default
  /// to fr
  Future changePassword({
    required String email,
    required String password,
    required String newPassword,
    required Function onSuccess,
    required Function(String) onError,
    bool secure = true,
    String appLocalization = 'fr'
  }) async {
    final url = Uri.parse(Genos.getChangePasswordUrl(secure));
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserEmail: email,
            gUserPassword: password,
            gUserNewPassword: newPassword,
            gAppLocalisation: appLocalization
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.errorMessage);
        } else {
          _preferences.put(key: gUserPassword, value: newPassword);
          onSuccess();
        }
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  ///Login the user with phone number
  ///[phoneNumber] the user phone number
  ///[onSuccess] is called when user is login and
  ///[onError] is called when an error occurred.
  ///[secure] when it set to true use https and http when it's set to false
  Future loginWithPhoneNumber({
    required String phoneNumber,
    required Function(String) onSuccess,
    required Function(String) onError,
    bool secure = true
  }) async {
    final url = Uri.parse(Genos.getPhoneAuthUrl(secure));
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserPhoneNumber: phoneNumber,
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.errorMessage);
        } else {
          User user = User(
              uid: result.data[gUserUId],
              phoneNumber: phoneNumber,
              mode: AuthenticationMode.phoneNumber
          );
          _preferences.putAll(user.toMap()..addAll({gUserPassword: user.password}));
          _getAuthenticationData();
          _notifyLoginListener(true);
          onSuccess(result.data[gUserUId]);
        }
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  ///Update the user phone number
  ///[phoneNumber] is the current phone number of the user
  ///[newPhoneNumber] is the new phone number to use
  ///[onSuccess] is call when the phone number is successfully updated
  ///[onError] is call when the request failed
  ///[secure] when it set to true use https and http when it's set to false
  Future changePhoneNumber({
    required String phoneNumber,
    required String newPhoneNumber,
    required Function() onSuccess,
    required Function(String) onError,
    bool secure = true
  }) async {
    final url = Uri.parse(Genos.getPhoneChangeUrl(secure));
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserUId: user!.uid,
            gUserPhoneNumber: phoneNumber,
            gNewUserPhoneNumber: newPhoneNumber
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.errorMessage);
        } else {
          _preferences.put(key: gUserPhoneNumber, value: newPhoneNumber);
          onSuccess();
        }
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  ///Login user with email and password
  ///[email] the email of the user
  ///[password] the password of the user
  ///[onSuccess] is called when the login is successful
  ///[onError] is called when the request terminate with failure
  ///[secure] when it set to true use https and http when it's set to false
  Future loginWithEmailAndPassword({
    required String email,
    required String password,
    required Function(User) onSuccess,
    required Function(String) onError,
    bool secure = true
  }) async {
    final url = Uri.parse(Genos.getEmailLoginUrl(secure));
    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserEmail: email,
            gUserPassword: password
          })
      );
      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          onError(result.errorMessage);
        } else {
          User user = User.fromMap(result.data);
          _preferences.putAll(user.toMap());
          _notifyLoginListener(true);
          _getAuthenticationData();
          onSuccess(user);
        }
      } else {
        onError(response.body.toString());
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  ///Change the email of the user
  ///[email] The current email of the user
  ///[newEmail] the new email to use
  ///[password] the user password
  ///[onEmailSent] Called when confirmation email is sent successful
  ///[onEmailConfirmed] is called when the user successfully confirm the
  ///   ownership of the email
  ///[onListenerDisconnected] is called when the confirmation listener is
  ///  unfortunately detached due to connection issue
  ///[onError] is called when an error occurred
  ///[secure] when it set to true use https and http when it's set to false
  Future changeEmail({
    required String newEmail,
    required String oldEmail,
    required String password,
    required Function onEmailSent,
    Function(String)? onListenerDisconnected,
    Function()? onEmailConfirmed,
    required Function(String) onError,
    bool secure = true
  }) async {
    final url = Uri.parse(Genos.getEmailChangeUrl(secure));

    WebSocketChannel channel;

    channel = createChannel('auth/email_confirmation/listen', secure);

    channel.sink.add(jsonEncode({
      gAppWsKey: Genos.appSignature,
      gUserEmail: newEmail
    }));
    channel.stream.listen((event) {

      User user = User.fromJson(event);
      //add user to preference
      _preferences.putAll(user.toMap());

      _getAuthenticationData();

      onEmailConfirmed?.call();
      channel.sink.close();

    }, onError: (e) {
      onError(e);

      onListenerDisconnected?.call(e.toString());
    }).onDone(() {
      onListenerDisconnected?.call('Done');
    });

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserEmail: oldEmail,
            gUserNewEmail: newEmail,
            gUserPassword: password
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          channel.sink.close();
          onError(result.errorMessage);
        } else {
          onEmailSent();
        }
      } else {
        channel.sink.close();
        onError(response.body.toString());
      }
    } catch (e) {
      channel.sink.close();
      onError(e.toString());
    }
  }

  ///[email] The email of the user
  ///[password] the user password
  ///[onEmailSent] Called when confirmation email is sent successful
  ///[onEmailConfirmed] is called when the user successfully confirm the
  ///   ownership of the email
  ///[onListenerDisconnected] is called when the confirmation listener is
  ///  unfortunately detached due to connection issue
  ///[onError] is called when an error occurred
  ///[secure] when it set to true use https and http when it's set to false
  Future signingWithEmailAndPassword({
    required String email,
    required String password,
    required Function onEmailSent,
    Function(String)? onListenerDisconnected,
    Function(User)? onEmailConfirmed,
    required Function(String) onError,
    bool secure = true
  }) async {
    final url = Uri.parse(Genos.getEmailSigningUrl(secure));

    WebSocketChannel channel;

    channel = createChannel('auth/email_confirmation/listen', secure);

    channel.sink.add(jsonEncode({
      gAppWsKey: Genos.appWsSignature,
      gUserEmail: email
    }));
    channel.stream.listen((event) {

      User user = User.fromJson(event);
      //add user to preference
      _preferences.putAll(user.toMap()..addAll({gUserPassword: password}));
      _getAuthenticationData();
      _notifyLoginListener(true);
      onEmailConfirmed?.call(user);
      channel.sink.close();

    }, onError: (e) {
      onListenerDisconnected?.call(e.toString());
    }).onDone(() {
    });

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-type': 'application/json',
          },
          body: jsonEncode({
            gAppSignature: Genos.appSignature,
            gUserEmail: email,
            gUserPassword: password
          })
      );

      if (response.statusCode == 200) {
        AuthResult result = AuthResult.fromJson(response.body);
        if (result.errorHappened) {
          channel.sink.close();
          onError(result.errorMessage);
        } else {
          onEmailSent();
        }
      } else {
        channel.sink.close();
        onError(response.body.toString());
      }
    } catch (e) {
      channel.sink.close();
      onError(e.toString());
    }
  }

  ///Log out the user.
  ///This will delete user authentication data on the device
  Future logOut() async {
    _user = null;
    await _preferences.putAll(User().toMap());
    _notifyLoginListener(false);
  }

  ///An instance of the [Auth]
  static Future<Auth> get instance async {
    if(!_initialized) {
      _preferences = await Preferences.getInstance();
      _getAuthenticationData();
      _initialized = true;
      return _instance;
    }
    return _instance;
  }

  ///Tells if the current user is authenticated or not
  bool get isAuthenticated => _user != null;

  ///The current user
  User? get user => _user;


}
