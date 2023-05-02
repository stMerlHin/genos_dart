import 'package:genos_dart/src/genos_dart_base.dart';
import 'package:genos_dart/src/utils/data_listener_provider.dart';

class SingleListenerObject  with SingleLowLevelDataListener {

  late Function(DataChange) notifyCallback;

  late String _table;
  late List<String> _tags;

  SingleListenerObject({
    required String table,
    required this.notifyCallback,
    required List<String> tags
  }) {
    _table = table;
    _tags = tags;
  }

  @override
  void notify(DataChange dataChange) {
    notifyCallback(dataChange);
  }

  @override
  String get table => _table;

  set table (String table) {
    _table = table;
  }

  set tags(List<String> tags) {
    _tags = tags;
  }

  @override
  List<String> get tags => _tags;

}