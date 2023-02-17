import 'package:meta/meta.dart';

import '../../genos_dart.dart';

class TaskWrapper with TaskBody {
  String taskId;
  late final Task task;

  TaskWrapper({
    required this.taskId,
  }) {
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
      task.cancel();
      notifyCancelListeners();
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
    return task.isPaused;
  }

  @override
  get result => task.result;

  void _setTaskListener() {
    task.setListener(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }
}

abstract class TaskListener {
  void onSuccess([s]);

  void onProgress(int percent);

  void onError([e]);

  void onPause() {}

  void onResume() {}
}

abstract class TaskStateNotifier {
  bool get isPaused;

  bool get isRunning;

  bool get isCanceled;

  bool get isCompleted;

  get result;
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
}

mixin TaskBody implements TaskRunner, TaskStateNotifier {
  @protected
  late List<TaskListener> listeners;

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
  Future<void> notifyPauseListeners() async {}

  @protected
  Future<void> notifyCancelListeners() async {}

  @protected
  Future<void> notifyResumeListeners() async {}

  void dispose(TaskListener observer) {
    listeners.removeWhere((element) => element == observer);
  }
}
