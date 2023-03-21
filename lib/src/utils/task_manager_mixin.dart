import 'package:meta/meta.dart';

import '../../genos_dart.dart';

mixin TaskManagerMixin {

  @protected
  static final List<TaskBody> tasks = [];
  @protected
  static final List<TaskManagerListener> listeners = [];

  @protected
  Future<void> addTask(TaskBody task) async {
    task.addListener(
        LinkedTaskListenerCallbacks(
          autoDispose: true,
          onSuccessCalled: _notifySuccessListener,
          onErrorCalled: _notifyErrorListener,
          onPauseCalled: _notifyPausedListener,
          onResumeCalled: _notifyResumeListener,
          onProgressCalled: _notifyProgressListener,
          onCancelCalled: _notifyCancelListener,
        )
    );
    tasks.insert(0, task);
    _notifyAddListener(task);
    await task.run();
  }

  void addListener(TaskManagerListener listener) {
    listeners.add(listener);
  }

  void _notifyAddListener(TaskBody task) {
    for (var element in listeners) {
      element.onNewTaskAdded(task);
    }
  }

  void _notifyProgressListener(int percent, [id]) {
    for (var element in listeners) {
      element.onAnyProgress(percent, id);
    }
  }

  void _notifyErrorListener([e, id]) {
    for (var element in listeners) {
      element.onAnyError(e, id);
    }
  }

  void _notifyCancelListener([id]) {
    for (var element in listeners) {
      element.onAnyCancel(id);
    }
  }

  void _notifyResumeListener([id]) {
    for (var element in listeners) {
      element.onAnyTaskResumed(id);
    }
  }

  void _notifySuccessListener([s, id]) {
    for (var element in listeners) {
      element.onAnySuccess(s, id);
    }
    tasks.removeWhere((element) {
      if (element.isCompleted) {
        return true;
      }
      return false;
    });
    _notifyDeleteListener(id);
  }

  void _notifyPausedListener([id]) {
    for (var element in listeners) {
      element.onAnyTaskPaused(id);
    }
  }

  void _notifyDeleteListener([id]) {
    for (var element in listeners) {
      element.onAnyTaskDeleted(id);
    }
  }

  void dispose(TaskManagerListener listener) {
    listeners.remove(listener);
  }

  void deleteTask(TaskBody task) {
    if (tasks.remove(task)) {
      _notifyDeleteListener((task as IdentifiedTaskRunner).id);
    }
  }


  List<TaskBody> get allTasks => tasks;
}


abstract class TaskManagerListener {
  void onNewTaskAdded(TaskBody task) {}
  void onAnyTaskDeleted([id]) {}
  void onAnySuccess([result, id]){}
  void onAnyTaskCanceled([id]) {}
  void onAnyTaskPaused([id]) {}
  void onAnyTaskResumed([id]) {}
  void onAnyError([e, id]) {}
  void onAnyCancel([id]) {}
  void onAnyProgress(int percent, [id]) {}
}
