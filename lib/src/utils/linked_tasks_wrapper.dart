import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class LinkedTasksWrapper extends IdentifiedTaskRunner
    with TaskBody, LinkedTaskBody
    implements TaskListener {
  @protected
  final List<TaskWrapper> tasksWrapper;
  bool _listenerAdded = false;
  bool _canceled = false;
  @protected
  late final String taskName;
  @protected
  late dynamic taskId;

  LinkedTasksWrapper(this.tasksWrapper, {
    String name = '',
    dynamic id,
  }) {
    listeners = [];
    initialTaskCount = tasksWrapper.length;
    currentTaskId = tasksWrapper.isNotEmpty ? tasksWrapper.first.id : '';
    taskName = name;
    taskId = id ?? Uuid().v1();
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      notifySuccessListeners(null, id);
    } else if (!isRunning) {
      _canceled = false;
      setTaskListener();
      await tasksWrapper.first.run();
    }
  }

  @override
  Future<void> pause() async {
    if (!isCompleted && isRunning) {
      await tasksWrapper.first.pause();
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifySuccessListeners(null, id);
    } else if (!isRunning) {
      _canceled = false;
      setTaskListener();
      await tasksWrapper.first.resume();
    }
  }

  @override
  Future<void> cancel() async {
    if (tasksWrapper.isNotEmpty && !isCompleted) {
      _canceled = true;
      await tasksWrapper.first.cancel();
      notifyCancelListeners(id);
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<TaskWrapper> tL = [
      ...tasksWrapper
          .where((element) => element.id == id && !element.isCompleted)
    ];
    if (tL.isNotEmpty) {
      await tL.first.cancel();
      await moveToNext();
    }
  }

  @override
  Future<void> notifySuccessListeners([e, id]) async {
    if (!isCompleted) {
      notifyPartialSuccessListeners(e, focusedTaskId);
      moveToNext();
    } else {
      if (currentProgress < 100) {
        currentProgress = 100;
        superNotifyProgressListeners(currentProgress, id);
      }
      super.notifySuccessListeners(e, id);
      moveToNext();
    }
  }

  @override
  Future<bool> moveToNext() async {
    _listenerAdded = false;
    if (tasksWrapper.isNotEmpty && !isCanceled && !isPaused) {
      tasksWrapper.removeAt(0);
      if (tasksWrapper.isNotEmpty) {
        currentTaskId = tasksWrapper.first.id;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted =>
      tasksWrapper.isEmpty || tasksWrapper.last.isCompleted;

  @override
  int get tasksLeft =>
      tasksWrapper.where((element) => !element.isCompleted).length;

  @override
  bool get result => tasksLeft == 0 ? true : false;

  @protected
  void setTaskListener() {
    if (!_listenerAdded) {
      tasksWrapper.first.addListener(this);
      _listenerAdded = true;
    }
  }

  @override
  bool get isCanceled => _canceled;

  @override
  bool get isPaused {
    if (tasksLeft > 0) {
      return tasksWrapper.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if (tasksLeft > 0) {
      return tasksWrapper.first.isRunning;
    }
    return false;
  }

  @protected
  @override
  void onError([e, id]) {
    notifyErrorListeners(e, id);
  }

  @protected
  @override
  void onPause([id]) {
    notifyPauseListeners(id);
  }

  @protected
  @override
  void onProgress(int percent, [id]) {
    notifyProgressListeners(percent, id);
  }

  @protected
  @override
  void onResume([id]) {
    notifyResumeListeners(id);
  }

  @protected
  @override
  void onSuccess([s, id]) {
    notifySuccessListeners(s, id);
  }

  @protected
  @override
  void onCancel([id]) {
    notifyCancelListeners(id);
  }

  @override
  String get name => taskName;

  @override
  get id => taskId;
}
