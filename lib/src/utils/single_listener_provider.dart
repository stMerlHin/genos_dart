
import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';

class SingleListenerProvider with SingleListenerProviderMixin {

  static final SingleListenerProvider _instance = SingleListenerProvider._();

  SingleListenerProvider._();

  static Future<SingleListenerProvider> get instance async => _instance;
}


mixin SingleListenerProviderMixin {
  @protected
  SingleListener? singleListener;
  @protected
  final List<SingleLowLevelDataListener> listeners = [];

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

  void refresh(SingleLowLevelDataListener listener, {bool commit = false}) {
    _updateSource(listener, commit);
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

  void _updateSource(SingleLowLevelDataListener listener, bool commit) {
    _dispose(listener, commit);
    addListener(listener);
  }

  int get listenerLength => listeners.length;

  void disposeAll() {
    singleListener?.dispose();
    listeners.clear();
    singleListener = null;
  }
}