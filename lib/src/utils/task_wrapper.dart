import 'package:meta/meta.dart';

import '../../genos_dart.dart';

abstract class TaskWrapper with TaskBody {
  String taskId;
  late final Task task;

  TaskWrapper({
    required this.taskId,
  }) {
    listeners = [];
  }

  @override
  Future<void> run() async {
    await task.run(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }

  @override
  Future<void> resume() async {
    await task.resume(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }

  @override
  Future<void> pause() async {
    await task.pause();
    notifyPauseListeners();
  }

  @override
  Future<void> cancel() async {
    task.cancel();
    notifyCancelListeners();
  }
}

abstract class TaskListener {
  void onError([e]);
  void onSuccess([s]);
  void onProgress(int percent);
  void onPause() {}
  void onResume() {}
}

mixin TaskState {
  @protected
  bool paused = true;

  @protected
  bool canceled = false;

  @protected
  bool completed = false;

  bool get isPaused => paused && !canceled && !completed;

  bool get isRunning => !paused && !canceled && !completed;

  bool get isCanceled => canceled;

  bool get isCompleted => completed;
}

abstract class TaskRunner {

  Future<void> run();

  Future<void> pause();

  Future<void> resume();

  Future<void> cancel();
}

mixin TaskBody implements TaskRunner {

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
