import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../genos_dart.dart';

class LinkedTasks extends IdentifiedTaskRunner with TaskBody, LinkedTaskBody {

  @protected
  final List<Task> tasks;
  bool _canceled = false;
  @protected
  late String taskId;
  @protected
  late String taskName;

  LinkedTasks(this.tasks, {
    String name = '',
    dynamic id,
}) {
    listeners = [];
    initialTaskCount = tasks.length;
    currentTaskId = tasks.isNotEmpty ? tasks.first.id : '';
    taskName = name;
    taskId = id ?? Uuid().v1;
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      notifySuccessListeners(null, id);
    } else if (!isRunning) {
      _canceled = false;
      setTaskListener();
      await tasks.first.run();
    }
  }

  @override
  Future<void> pause() async {
    if (!isCompleted && isRunning) {
      await tasks.first.pause();
      notifyPauseListeners(id);
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifySuccessListeners(null, id);
    } else if (!isRunning) {
      _canceled = false;
      setTaskListener();
      notifyResumeListeners(id);
      await tasks.first.resume();

    }
  }

  @override
  Future<void> cancel() async {
    if (tasks.isNotEmpty && !isCompleted && !isPaused) {
      _canceled = true;
      await tasks.first.cancel();
      notifyCancelListeners();
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<Task> tL = [
      ...tasks.where((element) => element.id == id && !element.isCompleted)
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
      await moveToNext();
    } else {
      if (currentProgress < 100) {
        currentProgress = 100;
        superNotifyProgressListeners(currentProgress, id);
      }
      super.notifySuccessListeners();
      await moveToNext();
    }
  }

  @override
  Future<bool> moveToNext() async {
    if (tasks.isNotEmpty && !isCanceled) {
      tasks.removeAt(0);
      if (tasks.isNotEmpty) {
        currentTaskId = tasks.first.id;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted => tasks.isEmpty || tasks.last.isCompleted;

  @override
  int get tasksLeft => tasks.where((element) => !element.isCompleted).length;

  @override
  bool get result => tasksLeft == 0 ? true : false;

  @protected
  void setTaskListener() {
    tasks.first.setListener(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }

  @override
  bool get isCanceled => _canceled;

  @override
  bool get isPaused {
    if (tasksLeft > 0) {
      return tasks.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if (tasksLeft > 0) {
      return tasks.first.isRunning;
    }
    return false;
  }

  @override
  get id => taskId;

  @override
  String get name => taskName;
}
