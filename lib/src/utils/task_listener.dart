import 'package:meta/meta.dart';

abstract class LinkedTaskListener extends TaskListener {
  void onPartialSuccess([id, result]);
  void onPartialError([id, e]);
}

class LinkedTaskListenerCallbacks extends LinkedTaskListener
    with TaskCallbacks {
  final void Function(dynamic, dynamic)? onPartialSuccessCalled;
  final void Function(dynamic, dynamic)? onPartialErrorCalled;

  LinkedTaskListenerCallbacks({
    required void Function() onSuccessCalled,
    required void Function(dynamic) onErrorCalled,
    this.onPartialSuccessCalled,
    this.onPartialErrorCalled,
    void Function(int)? onProgressCalled,
    void Function()? onPauseCalled,
    void Function()? onResumeCalled,
    void Function()? onCancelCalled,
  }) {
    this.onSuccessCalled = onSuccessCalled;
    this.onErrorCalled = onErrorCalled;
    this.onProgressCalled = onProgressCalled;
    this.onPauseCalled = onPauseCalled;
    this.onResumeCalled = onResumeCalled;
    this.onCancelCalled = onCancelCalled;
  }

  @mustCallSuper
  @override
  void onPartialError([id, e]) {
    onPartialErrorCalled?.call(id, e);
  }

  @mustCallSuper
  @override
  void onPartialSuccess([id, result]) {
    onPartialSuccessCalled?.call(id, result);
  }
}

abstract class TaskListener {
  void onSuccess([s]);

  void onProgress(int percent);

  void onError([e]);

  void onPause() {}

  void onResume() {}

  void onCancel() {}
}

mixin TaskCallbacks on TaskListener {
  late final void Function() onSuccessCalled;

  late final void Function(dynamic) onErrorCalled;

  late final void Function(int)? onProgressCalled;

  late final void Function()? onPauseCalled;

  late final void Function()? onResumeCalled;

  late final void Function()? onCancelCalled;

  @mustCallSuper
  @override
  void onCancel() {
    onCancelCalled?.call();
  }

  @override
  @mustCallSuper
  void onError([e]) {
    onErrorCalled(e);
  }

  @mustCallSuper
  @override
  void onProgress(int percent) {
    onProgressCalled?.call(percent);
  }

  @mustCallSuper
  @override
  void onSuccess([s]) {
    onSuccessCalled();
  }

  @mustCallSuper
  @override
  void onPause() {
    onPauseCalled?.call();
  }

  @mustCallSuper
  @override
  void onResume() {
    onResumeCalled?.call();
  }
}

class TaskListenerCallbacks extends TaskListener with TaskCallbacks {
  TaskListenerCallbacks({
    required void Function() onSuccessCalled,
    required void Function(dynamic) onErrorCalled,
    void Function(int)? onProgressCalled,
    void Function()? onPauseCalled,
    void Function()? onResumeCalled,
    void Function()? onCancelCalled,
  }) {
    this.onSuccessCalled = onSuccessCalled;
    this.onErrorCalled = onErrorCalled;
    this.onProgressCalled = onProgressCalled;
    this.onPauseCalled = onPauseCalled;
    this.onResumeCalled = onResumeCalled;
    this.onCancelCalled = onCancelCalled;
  }
}
