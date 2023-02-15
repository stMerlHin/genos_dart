import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../../genos_dart.dart';

class Preferences {
  static final Preferences _instance = Preferences._();
  static String _preferenceFilePath = '';
  static bool _initialized = false;
  static late Map<String, dynamic> _preferences;
  static bool _locked = false;

  Preferences._();

  ///Get an instance of preferences
  static Future<Preferences> getInstance() async {
    if (!_initialized) {
      //await Directory(Geno.appPrivateDirectory).create(recursive: true);
      _preferenceFilePath = join(Genos.appPrivateDirectory, preferenceFile);
      File gP = File(_preferenceFilePath);
      bool exist = await gP.exists();
      if (exist) {
        String str = await gP.readAsString();
        _preferences = jsonDecode(Obfuscator.decrypt(content: str) ?? '{}');
      } else {
        _preferences = {};
      }
      _initialized = true;
    }
    return _instance;
  }

  Future<void> put({required String key, dynamic value}) async {
    _preferences[key] = value;
    await _saveData();
  }

  Future<void> putAll(Map<String, dynamic> map) async {
    _preferences.addAll(map);
    await _saveData();
  }

  Future<void> _saveData() async {
    if (!_locked) {
      _locked = true;
      File f = File(_preferenceFilePath);
      await f
          .writeAsString(Obfuscator.encrypt(content: jsonEncode(_preferences)));
      _locked = false;
    }
  }

  String? getString(String key) {
    return _preferences[key];
  }

  int? getInt(String key) {
    return _preferences[key];
  }

  bool? getBool(String key) {
    return _preferences[key];
  }

  dynamic get(String key) {
    return _preferences[key];
  }
}

class Cache {
  final String cacheFilePath;
  static final Map<String, Cache> _instances = {};
  Map<String, dynamic> data;
  bool _locked = false;
  final bool encrypt;
  final String? encryptionKey;

  Cache._({
    required this.cacheFilePath,
    required this.data,
    required this.encrypt,
    this.encryptionKey,
  });

  Map<String, dynamic>? get(String key) {
    return data[key];
  }

  Future<bool> put(
      {String? uid,
      required Map<String, dynamic> map,
      bool save = true}) async {
    data[uid ?? Uuid().v1()] = map;
    if (save) {
      return await _cacheData();
    }
    return false;
  }

  Future<bool> putAll(Map<String, Map<String, dynamic>> map) async {
    data.addAll(map);
    return await _cacheData();
  }

  List<Map<String, dynamic>> getAll() {
    List<Map<String, dynamic>> list = [];
    data.forEach((key, value) {
      list.add(value);
    });
    return list;
  }

  Future<bool> remove(String key) async {
    data.remove(key);
    return await _cacheData();
  }

  Future<bool> _cacheData() async {
    if (!_locked) {
      _locked = true;
      File file = File(cacheFilePath);
      if (encrypt) {
        await file.writeAsString(
            Obfuscator.encrypt(content: jsonEncode(data), key: encryptionKey));
      } else {
        await file.writeAsString(jsonEncode(data));
      }
      _locked = false;
      return true;
    }
    return false;
  }

  static Future<Cache> getInstance({
    required String cacheFilePath,
    bool encrypt = true,
    String? encryptionKey,
  }) async {
    String cacheAbsolutePath = cacheFilePath;

    await Directory(Genos.appPrivateDirectory).create(recursive: true);
    cacheAbsolutePath = join(Genos.appPrivateDirectory, cacheFilePath);

    ///Check if an instance of the same cache is not already launched
    if (Cache._instances[cacheAbsolutePath] != null) {
      return Cache._instances[cacheAbsolutePath]!;
    }

    File file = File(cacheAbsolutePath);
    Map<String, dynamic> d = {};
    if (await file.exists()) {
      String str = await file.readAsString();
      if (encrypt) {
        d = jsonDecode(Obfuscator.decrypt(
              content: str,
              key: encryptionKey,
            ) ??
            '{}');
      } else {
        d = jsonDecode(str);
      }
    }
    return Cache._(
        cacheFilePath: cacheAbsolutePath,
        data: d,
        encrypt: encrypt,
        encryptionKey: encryptionKey);
  }

  void dispose() {
    Cache._instances.remove(cacheFilePath);
  }
}

class Obfuscator {
  ///[key] must 32 length
  ///the content to encrypt
  static String encrypt({
    String? key,
    required String content,
  }) {
    final encrypter = _createEncrypter(key ?? Genos.encryptionKey);

    final encrypted = encrypter.encrypt(content, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  static String? decrypt({String? key, required String content}) {
    final encrypter = _createEncrypter(key ?? Genos.encryptionKey);

    try {
      final decrypted = encrypter.decrypt(
          Encrypted(content.toBase64UInt8List()),
          iv: IV.fromLength(16));

      return decrypted;
    } catch (e) {
      return null;
    }
  }

  static Encrypter _createEncrypter(String key) {
    final encryptionKey = Key.fromUtf8(key);

    return Encrypter(AES(encryptionKey));
  }
}

extension StringUint8List on String {
  Uint8List toUInt8List() {
    return Uint8List.fromList(codeUnits);
  }

  Uint8List toBase64UInt8List() {
    return base64Decode(this);
  }
}

const String preferenceFile = '.gp';
