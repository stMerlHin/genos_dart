import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';

abstract class BaseDataListenerProvider {
  final Map<String, DataListener> dataListeners = {};
  final List<LowLevelDataListener> listeners = [];
  @protected
  static bool initialized = false;

  @protected
  void addListener(
    LowLevelDataListener listener,
    void Function() disposeCall, {
    bool reflexive = false,
    bool secure = true,
  }) {
    DataListener? l = dataListeners[listener.key];

    disposeCall();

    if (l == null) {
      l = DataListener(table: listener.table, tag: listener.tag);
      l.listen((DataChange dataChange) {
        listeners.where((element) {
          return element.key == l!.key;
        }).forEach((element) {
          element.notify(dataChange);
        });
      }, secure: secure, reflexive: reflexive);
      dataListeners[l.key];
    }
    listeners.add(listener);
  }

  @protected
  void disposeListener(LowLevelDataListener listener) {
    listeners.remove(listener);
    if (listeners.where((element) => element.key == listener.key).isEmpty) {
      dataListeners[listener.key]?.dispose();
      dataListeners.remove(listener.key);
    }
  }
}

class SingleListenerProvider {
  @protected
  SingleListener? singleListener;
  @protected
  final List<SingleLowLevelDataListener> listeners = [];
  final SingleListenerProvider _instance = SingleListenerProvider._();

  SingleListenerProvider._();

  Future<void> get instance async => _instance;

  @protected
  void addListener(
    SingleLowLevelDataListener listener, {
    bool secure = true,
  }) {
    listeners.add(listener);
    if (singleListener == null) {
      singleListener = SingleListener(
        tags: {
          listener.table: [listener.tagsValue]
        },
      );
      singleListener?.listen(
        (change) {
          for (var element in listeners) {
            element.notify(change);
          }
        },
        secure: secure,
        reflexive: true,
      );
    } else if (listeners
        .where((element) => element.key == listener.key)
        .isEmpty) {
      singleListener!.addSource(listener);
    }
  }

  void dispose(SingleLowLevelDataListener listener) {
    if (listeners.where((element) => element.key == listener.key).length > 1) {
      listeners.remove(listener);
    } else {
      listeners.remove(listener);
      if (listeners.isNotEmpty) {
        singleListener?.deleteSource(listener);
      } else {
        disposeAll();
      }
    }
  }

  void disposeAll() {
    singleListener?.dispose();
    listeners.clear();
  }
}

abstract class DataListenerAction {
  String get table;
  String? get key;
  void notify(DataChange dataChange);
}

mixin LowLevelDataListener implements DataListenerAction {
  String? get tag;

  @override
  String? get key => tag == null ? table : '$table/$tag';
}

mixin SingleLowLevelDataListener implements DataListenerAction {
  List<String?> get tags;

  @override
  String? get key => '$table/${tags.toSplitableString()}';
  String? get tagsValue => tags.toSplitableString();
}
