import 'package:genos_dart/genos_dart.dart';
import 'package:genos_dart/src/utils/single_listener_object.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() async {
  final String appSignature = '91a2dbf0-292d-11ed-91f1-4f98460f463c';
  final String appWsSignature = '91a2dbf0-292d-11ed-91f1-4f98460f464c';
  final String encryptionKey = '91a2dbf0-292d-11ed-91f1-4f98460f';
  final String appName = 'Genos';
  final String appPrivateDirectory = '.';
  final String appPublicDirectory = 'cd';
  final int tour = 3;

  await Genos.instance.initialize(
      appSignature: appSignature,
      appWsSignature: appWsSignature,
      encryptionKey: encryptionKey,
      appPrivateDirectory: appPrivateDirectory,
      appPublicDirectory: appPublicDirectory,
      tour: 3,
      appName: appName,
      onInitialization: (_) async {
        await GDirectRequest.select(
          sql: '',
        ).exec(
            secure: false,
            onSuccess: (_) {
              print('h');
            },
            onError: (err) {
            });
      });

  group('Genos initializing test', () {

    test('App name should be the one passed when genos is initialized', () async {
      expect(Genos.appName, appName);
    });

    test('App private directory should be the one passed when genos is initialized', () async {
      expect(Genos.appPrivateDirectory, appPrivateDirectory);
    });

    test('App public directory should be the one passed when genos is initialized', () async {
      expect(Genos.appPublicDirectory, appPublicDirectory);
    });

    test('App signature  should be the one passed when genos is initialized', () async {
      expect(Genos.appSignature, Auth.encodeBase64String(appSignature, tour));
    });

    test('App WS signature  should be the one passed when genos is initialized', () async {
      expect(Genos.appWsSignature, Auth.encodeBase64String(appWsSignature, tour));
    });


    test('App encryption key  should be the one passed when genos is initialized', () async {
      expect(Genos.encryptionKey, encryptionKey);
    });

  });

  group('SingleListener test', () {
    SingleListener listener = SingleListener(tags: {'jk': ['j']});
    listener.listen((p0) {});

    final String table = 'table';
    final String newTable = 'new_table';
    final SingleListenerObject listenerObject = SingleListenerObject(
        table: table,
        tags: ['u', 'i'],
        notifyCallback: (change) {}
    );

    final SingleListenerObject listenerObject2 = SingleListenerObject(
        table: table,
        tags: ['u', 'i'],
        notifyCallback: (change) {}
    );

    test("SingleListener tags should not be empty ", () {
      expect(listener.tags.isEmpty, isFalse);
    });

    test("Added source should appear on tag SingleListener list", () {
      listenerObject.init();
      listener.addSource(listenerObject);
      expect(listener.tags[listenerObject.table]?.first, listenerObject.tagsValue);
    });

    test("Adding another listening source with existing tags value should not affect the length of the source list", () {
      listenerObject2.init();
      listener.addSource(listenerObject2);
      expect(listener.tags[listenerObject2.table]?.length, 1);
    });

  });
}
