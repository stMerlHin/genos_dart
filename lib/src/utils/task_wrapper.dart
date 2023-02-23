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
      notifySuccessListeners(task.result);
    } else if (!isRunning) {
      _setTaskListener();
      await task.run();
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifyProgressListeners(100);
      notifySuccessListeners(task.result);
    } else if (!isRunning) {
      _setTaskListener();
      await task.resume();
    }
  }

  @override
  Future<void> pause() async {
    if (!isPaused) {
      await task.pause();
      notifyPauseListeners();
    }
  }

  @override
  Future<void> cancel() async {
    if (!isCanceled) {
      await task.cancel();
      notifyCancelListeners();
    }
  }

  @override
  Future<void> notifyProgressListeners(int percent) {
    currentProgress = percent;
    return super.notifyProgressListeners(percent);
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
  // TODO: implement name
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
  Future<void> notifySuccessListeners([e]) async {
    for (var element in listeners) {
      element.onSuccess(e);
    }
  }

  @protected
  Future<void> notifyErrorListeners([e]) async {
    for (var element in listeners) {
      element.onError(e);
    }
  }

  @protected
  Future<void> notifyProgressListeners(int percent) async {
    for (var element in listeners) {
      element.onProgress(percent);
    }
  }

  @protected
  Future<void> notifyPauseListeners() async {
    for (var element in listeners) {
      element.onPause();
    }
  }

  @protected
  Future<void> notifyCancelListeners() async {
    for (var element in listeners) {
      element.onCancel();
    }
  }

  @protected
  Future<void> notifyResumeListeners() async {
    for (var element in listeners) {
      element.onResume();
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
  Future<void> notifyProgressListeners(int percent) {
    currentProgress = (((initialTaskCount - tasksLeft) * 100) ~/ initialTaskCount) +
        percent ~/ initialTaskCount;
    return super.notifyProgressListeners(currentProgress);
  }

  Future<void> superNotifyProgressListeners(int percent) {
    return super.notifyProgressListeners(percent);
  }

  int get tasksLeft;
}
