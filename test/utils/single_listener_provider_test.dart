import 'package:genos_dart/genos_dart.dart';
import 'package:genos_dart/src/utils/single_listener_object.dart';
import 'package:test/test.dart';

///The content of this class is supposed to be the same with the
///[SingleListenerProvider] excepts methods with expose protected value
class SingleListenerProviderTestClass with SingleListenerProviderMixin {

  static final SingleListenerProviderTestClass _instance = SingleListenerProviderTestClass._();

  SingleListenerProviderTestClass._();

  static Future<SingleListenerProviderTestClass> get instance async => _instance;

  SingleListener? getSingleListener() => singleListener;

  List<SingleLowLevelDataListener> getListeners () {
    return listeners;
  }
}

void main() async {
  final SingleListenerProviderTestClass listenerProvider = await SingleListenerProviderTestClass.instance;

  await Genos.instance
      .initialize(
      encryptionKey: '',
      appSignature: '',
      appWsSignature: '',
      secureListener: false,
      appPrivateDirectory: '',
      onInitialization: (genos) async {

      });

  group('SingleListenerProvider', () {
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

    test("SingleListenerProvider's singleListener property should be by default null", () {
      expect(listenerProvider.getSingleListener(), isNull);
    });

    test("SingleListenerProvider listener length must be empty by default", () {
      expect(listenerProvider.listenerLength, 0);
    });

    group("Adding listener", () {
      test(
          'SingleListenerProvider should automatically initialize new added listeners', () {
        listenerProvider.addListener(listenerObject);
        expect(listenerObject.initialized, isTrue);
      });

      test("SingleListenerProvider listener length should be be incremented each time addListener method is called", () {
        expect(listenerProvider.listenerLength, 1);
        listenerProvider.addListener(listenerObject2);
        expect(listenerProvider.listenerLength, 2);
      });

      test("singleListener's tags length should be 1 as far as listeners tags are the same", () {
        expect(listenerProvider.getSingleListener()?.tags.length, 1);
      });

    });

    test("SingleListenerProvider listener list should contain the last added listener", () {
      expect(listenerProvider.getListeners().contains(listenerObject), isTrue);
    });


    group("Disposing listener", () {

      test("Disposing one listener should reduce listener list item to one item ", () {
        listenerProvider.dispose(listenerObject);
        expect(listenerProvider.listenerLength, 1);
        expect(listenerProvider.getSingleListener(), isNotNull);
      });

      test("Disposing all listeners should clear listener list and set singleListener property to null", () {
        listenerProvider.dispose(listenerObject2);
        expect(listenerProvider.listenerLength, isZero);
        expect(listenerProvider.getSingleListener(), isNull);
      });

    });


  });
}