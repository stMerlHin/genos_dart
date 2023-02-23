import 'package:genos_dart/genos_dart.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class LinkedTasksWrapper extends IdentifiedTaskRunner
    with TaskBody, LinkedTaskBody
    implements TaskListener {
  late List<TaskWrapper> _tasksWrapper;
  bool _listenerAdded = false;
  bool _canceled = false;
  @protected
  late final String taskName;
  @protected
  late dynamic taskId;

  LinkedTasksWrapper(List<TaskWrapper> tasksWrapper, {
    String name = '',
    dynamic id,
  }) {
    listeners = [];
    _tasksWrapper = tasksWrapper;
    initialTaskCount = tasksWrapper.length;
    currentTaskId = tasksWrapper.isNotEmpty ? tasksWrapper.first.id : '';
    taskName = name;
    taskId = id ?? Uuid().v1();
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      notifySuccessListeners();
    } else if (!isRunning) {
      _canceled = false;
      _setTaskListener();
      await _tasksWrapper.first.run();
    }
  }

  @override
  Future<void> pause() async {
    if (!isCompleted && isRunning) {
      await _tasksWrapper.first.pause();
    }
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      notifySuccessListeners();
    } else if (!isRunning) {
      _canceled = false;
      _setTaskListener();
      await _tasksWrapper.first.resume();
    }
  }

  @override
  Future<void> cancel() async {
    if (_tasksWrapper.isNotEmpty && !isCompleted) {
      _canceled = true;
      await _tasksWrapper.first.cancel();
      notifyCancelListeners();
    }
  }

  ///cancel the task identified by [id] if it does not already
  ///completed and remove it
  Future<void> cancelTask(dynamic id) async {
    List<TaskWrapper> tL = [
      ..._tasksWrapper
          .where((element) => element.id == id && !element.isCompleted)
    ];
    if (tL.isNotEmpty) {
      await tL.first.cancel();
      await moveToNext();
    }
  }

  @override
  Future<void> notifySuccessListeners([e]) async {
    if (!isCompleted) {
      notifyPartialSuccessListeners(_tasksWrapper.first.id, e);
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
    _listenerAdded = false;
    if (_tasksWrapper.isNotEmpty && !isCanceled && !isPaused) {
      _tasksWrapper.removeAt(0);
      if (_tasksWrapper.isNotEmpty) {
        currentTaskId = _tasksWrapper.first.id;
        run();
        return true;
      }
    }
    return false;
  }

  @override
  bool get isCompleted =>
      _tasksWrapper.isEmpty || _tasksWrapper.last.isCompleted;

  @override
  int get tasksLeft =>
      _tasksWrapper.where((element) => !element.isCompleted).length;

  @override
  bool get result => tasksLeft == 0 ? true : false;

  void _setTaskListener() {
    if (!_listenerAdded) {
      _tasksWrapper.first.addListener(this);
      _listenerAdded = true;
    }
  }

  @override
  bool get isCanceled => _canceled;

  @override
  bool get isPaused {
    if (tasksLeft > 0) {
      return _tasksWrapper.first.isPaused;
    }
    return false;
  }

  @override
  bool get isRunning {
    if (tasksLeft > 0) {
      return _tasksWrapper.first.isRunning;
    }
    return false;
  }

  @protected
  @override
  void onError([e]) {
    notifyErrorListeners(e);
  }

  @protected
  @override
  void onPause() {
    notifyPauseListeners();
  }

  @protected
  @override
  void onProgress(int percent) {
    notifyProgressListeners(percent);
  }

  @protected
  @override
  void onResume() {
    notifyResumeListeners();
  }

  @protected
  @override
  void onSuccess([s]) {
    notifySuccessListeners(s);
  }

  @protected
  @override
  void onCancel() {
    notifyCancelListeners();
  }

  @override
  // TODO: implement name
  String get name => taskName;

  @override
  // TODO: implement id
  get id => taskId;
}
