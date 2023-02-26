import 'package:meta/meta.dart';

import '../../genos_dart.dart';

abstract class TaskWrapper extends IdentifiedTaskRunner with TaskBody {
  @protected
  late final Task task;

  TaskWrapper() {
    listeners = [];
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      notifyProgressListeners(100);
      notifySuccessListeners(task.result, id);
    } else if (!isRunning) {
      _setTaskListener();
      await task.run();
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifyProgressListeners(100, id);
      notifySuccessListeners(task.result, id);
    } else if (!isRunning) {
      _setTaskListener();
      await task.resume();
    }
  }

  @override
  Future<void> pause() async {
    if (!isPaused) {
      await task.pause();
      notifyPauseListeners(id);
    }
  }

  @override
  Future<void> cancel() async {
    if (!isCanceled) {
      await task.cancel();
      notifyCancelListeners(id);
    }
  }

  @override
  bool get isCompleted {
    return task.completed;
  }

  @override
  bool get isCanceled {
    return task.isCanceled;
  }

  @override
  bool get isPaused {
    return task.isPaused;
  }

  @override
  bool get isRunning {
    return task.isRunning;
  }

  @override
  get result => task.result;

  @override
  get id => task.id;

  @override
  String get name => task.name;

  void _setTaskListener() {
    task.setListener(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }
}

abstract class TaskStateNotifier {
  bool get isPaused;

  bool get isRunning;

  bool get isCanceled;

  bool get isCompleted;

  get result;

  int get progress;
}

abstract class TaskStateHolder {
  @protected
  late bool paused;

  @protected
  late bool canceled;

  @protected
  late bool completed;
}

mixin TaskState implements TaskStateHolder, TaskStateNotifier {
  @override
  @protected
  bool paused = true;

  @override
  @protected
  bool canceled = false;

  @override
  @protected
  bool completed = false;

  @override
  bool get isPaused => paused && !canceled && !completed;

  @override
  bool get isRunning => !paused && !canceled && !completed;

  @override
  bool get isCanceled => canceled;

  @override
  bool get isCompleted => completed;
}

abstract class TaskRunner {
  Future<void> run();

  Future<void> pause();

  Future<void> resume();

  Future<void> cancel();

  String get name;
  //
  // @protected
  // Future<void> retry() {
  //   return resume();
  // }
}

abstract class IdentifiedTaskRunner extends TaskRunner {
  dynamic get id;
}

mixin TaskBody on TaskRunner implements TaskStateNotifier {
  @protected
  late List<TaskListener> listeners;

  @protected
  int currentProgress = 0;

  void addListener(TaskListener listener) {
    listeners.add(listener);
  }

  @protected
  Future<void> notifySuccessListeners([e, id]) async {
    for (var element in listeners) {
      element.onSuccess(e, id);
    }
  }

  @protected
  Future<void> notifyErrorListeners([e, id]) async {
    for (var element in listeners) {
      element.onError(e, id);
    }
  }

  @protected
  Future<void> notifyProgressListeners(int percent, [id]) async {
    currentProgress = percent;
    for (var element in listeners) {
      element.onProgress(percent, id);
    }
  }

  @protected
  Future<void> notifyPauseListeners([id]) async {
    for (var element in listeners) {
      element.onPause(id);
    }
  }

  @protected
  Future<void> notifyCancelListeners([id]) async {
    for (var element in listeners) {
      element.onCancel(id);
    }
  }

  @protected
  Future<void> notifyResumeListeners([id]) async {
    for (var element in listeners) {
      element.onResume([id]);
    }
  }

  void dispose(TaskListener observer) {
    listeners.removeWhere((element) => element == observer);
  }

  @override
  int get progress => currentProgress;
}

mixin LinkedTaskBody on TaskBody {
  @protected
  int initialTaskCount = 0;

  @protected
  late dynamic currentTaskId;

  @protected
  Future<bool> moveToNext();

  @protected
  Future<void> notifyPartialErrorListeners([id, e]) async {
    for (var element in listeners) {
      if (element is LinkedTaskListener) {
        element.onPartialError(id, e);
      }
    }
  }

  @protected
  Future<void> notifyPartialSuccessListeners([id, value]) async {
    for (var element in listeners) {
      if (element is LinkedTaskListener) {
        element.onPartialSuccess(id, value);
      }
    }
  }

  @override
  Future<void> notifyProgressListeners(int percent, [id]) {
    currentProgress = (((initialTaskCount - tasksLeft) * 100) ~/ initialTaskCount) +
        percent ~/ initialTaskCount;
    return super.notifyProgressListeners(currentProgress, id);
  }

  Future<void> superNotifyProgressListeners(int percent, [id]) {
    return super.notifyProgressListeners(percent, id);
  }

  int get tasksLeft;

  get focusedTaskId => currentTaskId;
}
