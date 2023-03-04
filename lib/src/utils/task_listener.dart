import 'package:meta/meta.dart';

mixin LinkedTaskListener implements TaskListener {
  void onPartialSuccess([result, id]);
  void onPartialError(e, [id]);
}

class LinkedTaskListenerCallbacks with LinkedTaskListener, TaskCallbacks {
  final void Function(dynamic, dynamic)? onPartialSuccessCalled;
  final void Function(dynamic, dynamic)? onPartialErrorCalled;
  @override
  bool disposed = false;

  LinkedTaskListenerCallbacks({
    required void Function([dynamic, dynamic]) onSuccessCalled,
    required void Function(dynamic, [dynamic]) onErrorCalled,
    this.onPartialSuccessCalled,
    this.onPartialErrorCalled,
    void Function(int, [dynamic])? onProgressCalled,
    void Function([dynamic])? onPauseCalled,
    void Function([dynamic])? onResumeCalled,
    void Function([dynamic])? onCancelCalled,
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
  void onPartialError([e, id]) {
    onPartialErrorCalled?.call(e, id);
  }

  @mustCallSuper
  @override
  void onPartialSuccess([result, id]) {
    onPartialSuccessCalled?.call(result, id);
  }

}

mixin TaskListener {
  bool disposed = false;
  void onSuccess([s, id]);

  void onProgress(int percent, [id]);

  void onError([e, id]);

  void onPause([id]) {}

  void onResume([id]) {}

  void onCancel([id]) {}
}

mixin TaskCallbacks on TaskListener {
  late final void Function([dynamic, dynamic]) onSuccessCalled;

  late final void Function(dynamic, [dynamic]) onErrorCalled;

  late final void Function(int, [dynamic])? onProgressCalled;

  late final void Function([dynamic])? onPauseCalled;

  late final void Function([dynamic])? onResumeCalled;

  late final void Function([dynamic])? onCancelCalled;

  @mustCallSuper
  @override
  void onCancel([id]) {
    onCancelCalled?.call(id);
  }

  @override
  @mustCallSuper
  void onError([e, id]) {
    onErrorCalled(e, id);
  }

  @mustCallSuper
  @override
  void onProgress(int percent, [id]) {
    onProgressCalled?.call(percent, id);
  }

  @mustCallSuper
  @override
  void onSuccess([s, id]) {
    onSuccessCalled(s, id);
  }

  @mustCallSuper
  @override
  void onPause([id]) {
    onPauseCalled?.call(id);
  }

  @mustCallSuper
  @override
  void onResume([id]) {
    onResumeCalled?.call(id);
  }
}

class TaskListenerCallbacks with TaskListener, TaskCallbacks {
  TaskListenerCallbacks({
    required void Function([dynamic, dynamic]) onSuccessCalled,
    required void Function(dynamic, [dynamic]) onErrorCalled,
    void Function(int, [dynamic])? onProgressCalled,
    void Function([dynamic])? onPauseCalled,
    void Function([dynamic])? onResumeCalled,
    void Function([dynamic])? onCancelCalled,
  }) {
    this.onSuccessCalled = onSuccessCalled;
    this.onErrorCalled = onErrorCalled;
    this.onProgressCalled = onProgressCalled;
    this.onPauseCalled = onPauseCalled;
    this.onResumeCalled = onResumeCalled;
    this.onCancelCalled = onCancelCalled;
  }
}
