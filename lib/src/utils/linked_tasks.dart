import '../../genos_dart.dart';

class LinkedTasks extends TaskRunner with TaskBody, LinkedTaskBody {
  late List<Task> _tasks;
  bool _canceled = false;

  LinkedTasks(List<Task> tasks) {
    listeners = [];
    _tasks = tasks;
    initialTaskCount = _tasks.length;
    currentTaskId = _tasks.isNotEmpty ? _tasks.first.id : '';
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      notifySuccessListeners();
    } else if (!isRunning) {
      _canceled = false;
      _setTaskListener();
      await _tasks.first.run();
    }
  }

  @override
  Future<void> pause() async {
    if (!isCompleted && isRunning) {
      await _tasks.first.pause();
      notifyPauseListeners();
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifySuccessListeners();
    } else if (!isRunning) {
      _canceled = false;
      _setTaskListener();
      notifyResumeListeners();
      await _tasks.first.resume();

    }
  }

  @override
  Future<void> cancel() async {
    if (_tasks.isNotEmpty && !isCompleted && !isPaused) {
      _canceled = true;
      await _tasks.first.cancel();
      notifyCancelListeners();
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<Task> tL = [
      ..._tasks.where((element) => element.id == id && !element.isCompleted)
    ];
    if (tL.isNotEmpty) {
      await tL.first.cancel();
      await moveToNext();
    }
  }

  @override
  Future<void> notifySuccessListeners([e]) async {
    if (!isCompleted) {
      notifyPartialSuccessListeners(_tasks.first.id, e);
      await moveToNext();
    } else {
      if (currentProgress < 100) {
        currentProgress = 100;
        superNotifyProgressListeners(currentProgress);
      }
      super.notifySuccessListeners();
      await moveToNext();
    }
  }

  @override
  Future<bool> moveToNext() async {
    if (_tasks.isNotEmpty && !isCanceled) {
      _tasks.removeAt(0);
      if (_tasks.isNotEmpty) {
        currentTaskId = _tasks.first.id;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted => _tasks.isEmpty || _tasks.last.isCompleted;

  @override
  int get tasksLeft => _tasks.where((element) => !element.isCompleted).length;

  @override
  bool get result => tasksLeft == 0 ? true : false;

  void _setTaskListener() {
    _tasks.first.setListener(
        onSuccess: notifySuccessListeners,
        onError: notifyErrorListeners,
        onProgress: notifyProgressListeners);
  }

  @override
  bool get isCanceled => _canceled;

  @override
  bool get isPaused {
    if (tasksLeft > 0) {
      return _tasks.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if (tasksLeft > 0) {
      return _tasks.first.isRunning;
    }
    return false;
  }
}
