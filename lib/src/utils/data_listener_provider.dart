import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';

abstract class BaseDataListenerProvider {

  final Map<String, DataListener> dataListeners = {};
  final List<LowLevelDataListener> listeners = [];
  @protected
  static bool initialized = false;


  @protected
  void addListener(LowLevelDataListener listener,
      void Function() disposeCall,{
        bool reflexive = false,
        bool secure = true,
      }) {
    DataListener? l = dataListeners[listener.key];

    disposeCall();

    if (l == null) {
      l = DataListener(
          table: listener.table,
          tag: listener.tag
      );
      l.listen((DataChange dataChange) {
        listeners.where((element) {
          return element.key == l!.key;
        }).forEach((element) {
          element.notify(dataChange);
        });
      },
          secure: secure,
          reflexive: reflexive
      );
      dataListeners[l.key];
    }
    listeners.add(listener);
  }

  @protected
  void disposeListener(LowLevelDataListener listener) {
    listeners.remove(listener);
    if(listeners.where((element) => element.key == listener.key).isEmpty) {
      dataListeners[listener.key]?.dispose();
      dataListeners.remove(listener.key);
    }
  }
}

mixin LowLevelDataListener {
  String get table;
  String? get tag;

  void notify(DataChange dataChange);

  String get key => tag == null ? table : '$table/$tag';
}
