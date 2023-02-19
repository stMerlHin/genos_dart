
import 'package:meta/meta.dart';

import '../../genos_dart.dart';

class LinkedTasks extends TaskRunner with TaskBody {
  late List<Task> _tasks;
  @protected
  late dynamic currentTaskId;
  bool _canceled = false;

  @protected
  int progress = 0;

  LinkedTasks(List<Task> tasks) {
    _tasks = tasks;
    currentTaskId = tasks.isNotEmpty ? _tasks.first.id : '';
  }

  @override
  Future<void> run() async {
    if(isCompleted) {
      notifySuccessListeners();
    } else if(!isRunning) {
      _setTaskListener();
      await _tasks.first.run();

    }
  }

  @override
  Future<void> pause() async {
    if(!isCompleted && isRunning) {
      await _tasks.first.pause();
    }
  }

  @override
  Future<void> resume() async {
    if(!isCompleted && tasksLeft != 0 && !isRunning) {
      _setTaskListener();
      await _tasks.first.resume();
    }
  }

  @override
  Future<void> cancel() async {
    if(_tasks.isNotEmpty) {
      await _tasks.first.cancel();
      _canceled = true;
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<Task> tL = [..._tasks.where(
            (element) => element.id == id && !element.isCompleted)
    ];
    if(tL.isNotEmpty) {
      await tL.first.cancel();
    }
    await moveToNext();
  }

  @override
  Future<void> notifyProgressListeners(int percent) {
    if(tasksLeft != 0) {
      progress = percent ~/ tasksLeft;
    } else {
      progress = percent;
    }
    return super.notifyProgressListeners(progress);
  }

  @override
  Future<void> notifySuccessListeners([e]) async {
    if(!isCompleted) {
      notifyPartialSuccessListeners(_tasks.first.id, e);
      await moveToNext();
    } else {
      notifySuccessListeners();
      await moveToNext();
    }
  }

  @protected
  Future<void> notifyPartialErrorListeners([id, e]) async {
    for (var element in listeners) {
      if(element is LinkedTaskListener) {
        element.onPartialError(id, e);
      }
    }
  }

  @protected
  Future<void> notifyPartialSuccessListeners([id, value]) async {
    for (var element in listeners) {
      if(element is LinkedTaskListener) {
        element.onPartialSuccess(id, value);
      }
    }
  }


  Future<bool> moveToNext() async {
    if(_tasks.isNotEmpty) {
      _tasks.removeAt(0);
      if(_tasks.isNotEmpty) {
        currentTaskId = _tasks.first.id;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted => _tasks.isEmpty
      || _tasks.last.isCompleted;

  int get tasksLeft => _tasks.where(
          (element) => !element.isCompleted
  ).length;

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
    if(tasksLeft > 0) {
      return _tasks.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if(tasksLeft > 0) {
      return _tasks.first.isRunning;
    }
    return false;
  }
}