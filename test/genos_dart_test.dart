import 'package:genos_dart/genos_dart.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('A group of tests', () {
    final Genos geno = Genos.instance;

    setUp(() {
      // Additional setup goes here.
    });

    test('Connexion error test while doing request', () async {
      await geno.initialize(
          appSignature: '91a2dbf0-292d-11ed-91f1-4f98460f463c',
          appWsSignature: '91a2dbf0-292d-11ed-91f1-4f98460f464c',
          encryptionKey: '91a2dbf0-292d-11ed-91f1-4f98460f',
          appPrivateDirectory: '.',
          onInitialization: (_) async {
            await GDirectRequest.select(
              sql: '',
            ).exec(
                secure: false,
                onSuccess: (_) {
                  print('h');
                },
                onError: (err) {
                  expect(err, 'Connection refused');
                });
          });
    });

    test('Generate uid', () async {
      expect(Uuid().v1(), Uuid().v1());
    });
  });
}
