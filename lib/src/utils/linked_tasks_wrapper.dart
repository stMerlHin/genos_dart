import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';

class LinkedTasksWrapper extends TaskRunner with TaskBody implements TaskListener {
  late List<TaskWrapper> _tasksWrapper;
  @protected
  late dynamic currentTaskId;
  bool _listenerAdded = false;
  bool _canceled = false;

  @protected
  int progress = 0;

  LinkedTasksWrapper(List<TaskWrapper> tasksWrapper) {
    _tasksWrapper = tasksWrapper;
    currentTaskId = tasksWrapper.isNotEmpty ? tasksWrapper.first.taskId : '';
  }

  @override
  Future<void> run() async {
    if(isCompleted) {
      notifySuccessListeners();
    } else if(!isRunning) {
      _setTaskListener();
      await _tasksWrapper.first.run();

    }
  }

  @override
  Future<void> pause() async {
    if(!isCompleted && isRunning) {
      await _tasksWrapper.first.pause();
    }
  }

  @override
  Future<void> resume() async {
    if(!isCompleted && tasksLeft != 0 && !isRunning) {
      _setTaskListener();
      await _tasksWrapper.first.resume();
    }
  }

  @override
  Future<void> cancel() async {
    if(_tasksWrapper.isNotEmpty) {
      await _tasksWrapper.first.cancel();
      _canceled = true;
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<TaskWrapper> tL = [..._tasksWrapper.where(
            (element) => element.taskId == id && !element.isCompleted)
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
      notifyPartialSuccessListeners(_tasksWrapper.first.taskId, e);
      await moveToNext();
    } else {
      notifySuccessListeners();
      await moveToNext();
    }
  }

  @override
  Future<void> notifyErrorListeners([e]) {
    return super.notifyErrorListeners(e);
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
    if(_tasksWrapper.isNotEmpty) {
      _tasksWrapper.removeAt(0);
      if(_tasksWrapper.isNotEmpty) {
        currentTaskId = _tasksWrapper.first.taskId;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted => _tasksWrapper.isEmpty
      || _tasksWrapper.last.isCompleted;

  int get tasksLeft => _tasksWrapper.where(
          (element) => !element.isCompleted
  ).length;

  @override
  bool get result => tasksLeft == 0 ? true : false;

  void _setTaskListener() {
    if(!_listenerAdded) {
      _tasksWrapper.first.addListener(this);
      _listenerAdded = true;
    }
  }

  @override
  bool get isCanceled => _canceled;

  @override
  bool get isPaused {
    if(tasksLeft > 0) {
      return _tasksWrapper.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if(tasksLeft > 0) {
      return _tasksWrapper.first.isRunning;
    }
    return false;
  }

  @override
  void onError([e]) {
    notifyErrorListeners(e);
  }

  @override
  void onPause() {
    notifyPauseListeners();
  }

  @override
  void onProgress(int percent) {
    notifyProgressListeners(percent);
  }

  @override
  void onResume() {
    notifyResumeListeners();
  }

  @override
  void onSuccess([s]) {
    notifySuccessListeners(s);
  }
}