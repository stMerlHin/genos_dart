import 'package:genos_dart/src/utils/single_listener_object.dart';
import 'package:test/test.dart';

void main() async {

  group('A group of tests', () {
    final String table = 'table';
    final String newTable = 'new_table';
    final SingleListenerObject listenerObject = SingleListenerObject(
        table: table,
        tags: ['u', 'i'],
        notifyCallback: (change) {}
    );

    test("SingleListenerObject should not be initialized until init or update method is called", () {
      expect(listenerObject.initialized, isFalse);
    });

    test("SingleListenerObject should be initialized once init or update method is called", () {
      listenerObject.init();
      expect(listenerObject.initialized, isTrue);
    });

    test(
        'SingleListenerObject key should be a concatenation of table name and tags separated with / ', () {
          expect(listenerObject.key, 'table/u/i');
        });

    test(
        'SingleListenerObject tags value should be a concatenation of tags list content separated with / ', () {
          listenerObject.init();
          expect(listenerObject.tagsValue, 'u/i');
        });


    test("Table name should be change", () {
      //Update table name
      listenerObject.table = newTable;
      expect(listenerObject.table, newTable);
    });

    test("Updating tags values should not change until update is called if tags has changed", () {
      listenerObject.tags = ['tilte'];
      expect(listenerObject.tagsValue, 'u/i');
    });

    test("Tags values should change to the new values of tags list content when update is called", () {
      listenerObject.update();
      expect(listenerObject.tagsValue, 'tilte');
    });

  });
}