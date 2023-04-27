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
  static final SingleListenerProvider _instance = SingleListenerProvider._();

  SingleListenerProvider._();

  static Future<SingleListenerProvider> get instance async => _instance;

  void addListener(
    SingleLowLevelDataListener listener, {
    bool secure = true,
  }) {
    
    listener.init();
    
    if (singleListener == null) {
      singleListener = SingleListener(
        tags: {
          listener.table: [listener.tagsValue]
        },
      );
      singleListener?.listen(
        (change) {
          if(change.tag == 'genos.all') {
            listeners.where((element) => element.table == change.table
            ).forEach((element) {
              element.notify(change);
            });
          } else if (change.changeType == ChangeType.none) {
            for (var element in listeners) {
              element.notify(change);
            }
          } else {
            listeners.where((element) => element.table == change.table
            ).forEach((element) {
              bool shouldSink = true;
              if (element.tags.isNotEmpty) {
                //for (var ele in element.tags) {
                if (change.tag != element.tagsValue) {
                  shouldSink = false;
                  //}
                }
              }
              if (shouldSink) {
                element.notify(change);
              }
            });
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
    listeners.add(listener);
  }
  
  void update(SingleLowLevelDataListener listener) {
    _updateSource(listener);
    listener.update();
  }

  void dispose(SingleLowLevelDataListener listener) {
    _dispose(listener);
  }

  void _dispose(SingleLowLevelDataListener listener, [bool commit = true]) {
    if (listeners.where((element) => element.key == listener.key).length > 1) {
      listeners.remove(listener);
    } else {
      listeners.remove(listener);
      if (listeners.isNotEmpty) {
        singleListener?.deleteSource(listener, commit: commit);
      } else {
        disposeAll();
      }
    }
  }

  void _updateSource(SingleLowLevelDataListener listener) {
    _dispose(listener, false);
    addListener(listener);
  }

  void disposeAll() {
    singleListener?.dispose();
    listeners.clear();
  }
}

abstract class DataListenerAction {
  String get table;
  String get key;
  void notify(DataChange dataChange);
}

mixin LowLevelDataListener implements DataListenerAction {
  String? get tag;

  @override
  String get key => tag == null ? table : '$table/$tag';
}

mixin SingleLowLevelDataListener implements DataListenerAction {
  List<String?> get tags;
  
  List<String?> get effectiveValues => _effectiveValues;
  
  late List<String?> _effectiveValues;

  void _init() {
    _effectiveValues = tags;
  }
  
  @mustCallSuper
  void init() {
    _init();
  }

  @mustCallSuper
  void update() {
    _init();
  }

  @override
  String get key => '$table/${effectiveValues.toSplitableString()}';
  String get tagsValue => effectiveValues.toSplitableString();
}
