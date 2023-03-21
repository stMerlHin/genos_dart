import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../genos_dart.dart';

typedef OnDownloadProgressCallback = void Function(
    int receivedBytes, int totalBytes);

typedef OnUploadProgressCallback = void Function(int);
typedef TaskProgressCallback = void Function(int);
typedef CompletedTaskCallback = void Function(dynamic);
typedef AsyncCompletedTaskCallback = Future<void> Function(dynamic, [bool]);

class DownloadTask extends Task {
  final String savePath;
  late FileMode fileMode;
  int _downloadedByte = 0;
  bool _acceptRangeRequest = false;
  late final dynamic _id;

  DownloadTask({
    required String url,
    required dynamic id,
    required this.savePath,
    required this.fileMode,
    String? name = '',
    int? retryCount,
    Duration? retryDelay,
    bool trustBadCertificate = false,
    int start = 0,
    Map<String, dynamic> headers = const {},
  }) {
    this.url = url;
    _id = id ?? Uuid().v1();
    super.retryDelay = retryDelay ?? const Duration(seconds: 2);
    this.start = start;
    file = File(savePath);
    taskName = name ?? '';
    this.retryCount = retryCount ?? 10;
    badCertificateCallback =
        ((X509Certificate cert, String host, int port) => trustBadCertificate);
    this.headers = headers;
  }

  factory DownloadTask.resume({
    required String url,
    dynamic id,
    required String savePath,
    required int start,
    Duration? retryDelay,
    String? name,
    int? retryCount,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return DownloadTask(
        url: url,
        id: id,
        retryDelay: retryDelay,
        retryCount: retryCount,
        savePath: savePath,
        start: start,
        name: name,
        trustBadCertificate: trustBadCertificate,
        fileMode: FileMode.append,
        headers: headers);
  }

  factory DownloadTask.create({
    required String url,
    dynamic id,
    required String savePath,
    Duration? retryDelay,
    int? retryCount,
    String? name,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return DownloadTask(
      url: url,
      id: id,
      name: name,
      retryDelay: retryDelay,
      retryCount: retryCount,
      savePath: savePath,
      trustBadCertificate: trustBadCertificate,
      fileMode: FileMode.write,
      headers: headers,
    );
  }

  factory DownloadTask.resumeFromFile({
    required String url,
    dynamic id,
    String? name,
    required String filePath,
    Duration? retryDelay,
    int? retryCount,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    File file = File(filePath);
    bool exists = file.existsSync();
    int length = 0;
    if (exists) {
      length = file.lengthSync();
    }
    return DownloadTask.resume(
      url: url,
      savePath: filePath,
      retryDelay: retryDelay,
      retryCount: retryCount,
      id: id,
      name: name,
      start: length,
      trustBadCertificate: trustBadCertificate,
      headers: headers,
    );
  }

  int get downloadedByte => _downloadedByte;

  @override
  Future<void> run() async {
    if (completed) {
      onSuccess(file.path);
    } else if (!isRunning) {
      final HttpClient httpClient =
          getHttpClient(onBadCertificate: badCertificateCallback);

      resetRetryingCount();

      paused = false;
      canceled = false;

      try {
        request = await httpClient.getUrl(Uri.parse(url));
        request.headers.add(HttpHeaders.rangeHeader, 'bytes=$start -');

        ///add user specific headers data
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });

        var httpResponse = await request.close();
        //String errorMessage = httpResponse.reasonPhrase;

        if (!runOnce) {
          _acceptRangeRequest =
              httpResponse.headers[HttpHeaders.acceptRangesHeader] != null;
          await stabilizeTask();
          fileSize = httpResponse.contentLength + start;
          _downloadedByte = start;
          runOnce = true;
        } else {
          await stabilizeTask();
        }

        if (httpResponse.statusCode == 200 && !isCompleted) {
          var downloadedFile = file.openSync(mode: fileMode);

          _subscription = httpResponse.listen(
            (data) {
              _downloadedByte += data.length;

              downloadedFile.writeFromSync(data);
              currentProgress = ((_downloadedByte / fileSize) * 100).toInt();
              onProgress?.call(currentProgress);
            },
            onDone: () {
              downloadedFile.closeSync();
              taskResult = file.path;
              completed = true;
              onSuccess(file.path);
            },
            onError: (e) {
              downloadedFile.closeSync();
              paused = true;
              throw e;
            },
            cancelOnError: true,
          )..onError((e) async {
              paused = true;
              await onError('Connection error');
            });
        } else {
          paused = true;
          await onError(await Task.responseAsString(httpResponse), false);
        }
      } on FileSystemException {
        paused = true;
        onError('File system error', false);
      } on SocketException {
        paused = true;
        await onError('Host unreachable');
      } catch (e) {
        paused = true;
        await onError(e.toString());
      }
    }
  }

  @override
  Future<void> cancel() async {
    if (!isCompleted) {
      canceled = true;
      paused = false;
      try {
        await _subscription.cancel();
      } catch (_) {}
      try {
        request.abort();
      } catch (_) {}
      try {
        file.deleteSync();
      } catch (_) {}
      start = 0;
      _downloadedByte = 0;
      fileMode = FileMode.write;
    }
  }

  @override
  Future<bool> pause() async {
    if (!canceled) {
      await _subscription.cancel();
      paused = true;
      request.abort();
    }
    return paused;
  }

  @override
  Future<void> resume() async {
    if (completed) {
      onSuccess(file.path);
    } else if (!isRunning) {
      start = _downloadedByte;
      fileMode = FileMode.append;
      await run();
    }
  }

  @override
  Future<void> stabilizeTask() async {
    if (!_acceptRangeRequest) {
      start = 0;
      _downloadedByte = 0;
      fileMode = FileMode.write;
    }
  }

  @override
  String? get result => taskResult;

  @override
  get id => _id;
}

class UploadTask extends Task {
  int _uploadedByte = 0;
  final bool multipart;
  late final dynamic _id;

  UploadTask({
    required String url,
    required File file,
    required dynamic id,
    required int retryCount,
    required String? name,
    Duration? retryDelay,
    required this.multipart,
    bool trustBadCertificate = false,
    int start = 0,
    Map<String, dynamic> headers = const {},
  }) {
    _id = id ?? Uuid().v1();
    this.url = url;
    this.start = start;
    this.file = file;
    taskName = name ?? '';
    this.retryDelay = retryDelay ?? const Duration(seconds: 2);
    this.retryCount = retryCount;
    badCertificateCallback =
        ((X509Certificate cert, String host, int port) => trustBadCertificate);
    this.headers = headers;
  }

  factory UploadTask.resume({
    required String url,
    required File file,
    required int start,
    dynamic id,
    int retryCount = 10,
    String? name,
    Duration? retryDelay,
    bool multipart = false,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return UploadTask(
        url: url,
        id: id,
        name: name,
        retryCount: retryCount,
        file: file,
        retryDelay: retryDelay,
        start: start,
        multipart: false,
        trustBadCertificate: trustBadCertificate,
        headers: headers);
  }

  factory UploadTask.create({
    required String url,
    required File file,
    dynamic id,
    int retryCount = 10,
    String? name,
    Duration? retryDelay,
    bool multipart = false,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return UploadTask(
      url: url,
      id: id,
      name: name,
      retryDelay: retryDelay,
      retryCount: retryCount,
      multipart: false,
      file: file,
      trustBadCertificate: trustBadCertificate,
      headers: headers,
    );
  }

  Future<void> _streamUpload({
    required int start,
    required Map<String, dynamic> headers,
    required OnUploadProgressCallback? onUploadProgress,
  }) async {
    paused = false;
    canceled = false;
    final fileStream = file.openRead(start);
    int size = 0;
    if (!runOnce) {
      fileSize = file.lengthSync() - start;
      size = fileSize;
      _uploadedByte = start;
      runOnce = true;
    } else {
      size = file.lengthSync() - start;
      print('size $size');
    }
    try {
      final httpClient = _getHttpClient(
          onBadCertificate: ((X509Certificate cert, String host, int port) =>
              true));

      request = await httpClient.postUrl(Uri.parse(url));

      request.headers
          .set(HttpHeaders.contentTypeHeader, ContentType.binary.mimeType);

      //request.headers.add(gFileName, path.basename(file.path));

      headers.forEach((key, value) {
        request.headers.add(key, '$value');
      });

      request.contentLength = size;

      Stream<List<int>> streamUpload = fileStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (!paused && !canceled) {
              _uploadedByte += data.length;
              currentProgress = ((_uploadedByte / fileSize) * 100).toInt();
              if (onUploadProgress != null) {
                onUploadProgress(currentProgress);
              }

              sink.add(data);
            }
          },
          handleError: (error, stack, sink) {
            print(error.toString());
            //throw error;
          },
          handleDone: (sink) {
            sink.close();
            // UPLOAD DONE;
          },
        ),
      );

      await request.addStream(streamUpload);

      final httpResponse = await request.close();

      if (httpResponse.statusCode != 200) {
        paused = true;
        await onError(await Task.responseAsString(httpResponse), false);
      } else {
        taskResult = await Task.responseAsString(httpResponse);
        completed = true;
        return onSuccess(taskResult!);
      }
    } on FileSystemException {
      paused = true;
      onError('File system error', false);
    } on SocketException {
      paused = true;
      await onError('Host unreachable');
    } catch (e) {
      if (!e.toString().contains('aborted')) {
        paused = true;
        await onError(e.toString());
      }
    }
  }

  static Future<void> _fileUploadMultipart({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    OnUploadProgressCallback? onProgress,
    Map<String, String> headers = const {},
    required MediaType mediaType,
    required String destination,
  }) async {
    final url = destination;
    final httpClient = _getHttpClient(
        onBadCertificate: ((X509Certificate cert, String host, int port) =>
            true));
    try {
      final request = await httpClient.postUrl(Uri.parse(url));

      int byteCount = 0;
      int currentProgress = 0;

      var multipart = await http.MultipartFile.fromPath(
          path.basename(file.path), file.path,
          contentType: mediaType);

      // final fileStreamFile = file.openRead();

      // var multipart = MultipartFile("file", fileStreamFile, file.lengthSync(),
      //     filename: fileUtil.basename(file.path));

      http.MultipartRequest requestMultipart =
          http.MultipartRequest("POST", Uri.parse(url));

      requestMultipart.files.add(multipart);

      var msStream = requestMultipart.finalize();

      var totalByteLength = requestMultipart.contentLength;

      request.contentLength = totalByteLength;

      headers.forEach((key, value) {
        request.headers.add(key, value);
      });

      request.headers.set(HttpHeaders.contentTypeHeader,
          requestMultipart.headers[HttpHeaders.contentTypeHeader]!);

      Stream<List<int>> streamUpload = msStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(data);

            byteCount += data.length;

            if (onProgress != null) {
              if (currentProgress != ((byteCount / totalByteLength) * 100).toInt()) {
                onProgress(((byteCount / totalByteLength) * 100).toInt());
                currentProgress = ((byteCount / totalByteLength) * 100).toInt();
              }
              // CALL STATUS CALLBACK;
            }
          },
          handleError: (error, stack, sink) {
            throw error;
          },
          handleDone: (sink) {
            sink.close();
            // UPLOAD DONE;
          },
        ),
      );

      await request.addStream(streamUpload);

      final httpResponse = await request.close();
//
      var statusCode = httpResponse.statusCode;

      if (statusCode ~/ 100 != 2) {
        onError(await Task.responseAsString(httpResponse));
      } else {
        onSuccess(await Task.responseAsString(httpResponse));
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  static Future<void> _uploadImage({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    required String destination,
    Map<String, String> headers = const {},
    OnUploadProgressCallback? onProgress,
  }) async {
    return _fileUploadMultipart(
        onSuccess: onSuccess,
        onError: onError,
        file: file,
        destination: destination,
        headers: headers,
        onProgress: onProgress,
        mediaType: MediaType(
            'image', path.extension(file.path).replaceRange(0, 1, '')));
  }

  static Future<void> _uploadDoc({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    required String destination,
    Map<String, String> headers = const {},
    OnUploadProgressCallback? onProgress,
  }) async {
    return _fileUploadMultipart(
        file: file,
        onError: onError,
        destination: destination,
        onProgress: onProgress,
        headers: headers,
        onSuccess: onSuccess,
        mediaType: MediaType(
            'application', path.extension(file.path).replaceRange(0, 1, '')));
  }

  static HttpClient _getHttpClient({
    required BadCertificateCallback onBadCertificate,
    Duration connectionTimeOut = const Duration(seconds: 10),
  }) {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = connectionTimeOut
      ..badCertificateCallback = onBadCertificate;
    return httpClient;
  }

  @override
  Future<void> run() async {
    if (isCompleted) {
      onSuccess(taskResult!);
    } else if (!isRunning) {
      resetRetryingCount();
      await _streamUpload(
          onUploadProgress: onProgress, headers: headers, start: start);
    } else {
      onError("Task is already in Running state");
    }
  }

  @override
  Future<void> cancel() async {
    //await _subscription.cancel();
    canceled = true;
    request.abort();
    _uploadedByte = 0;
  }

  @override
  Future<void> pause() async {
    paused = true;
    //canceled = false;
    request.abort();
    //await Future.delayed(Duration(seconds: 1));
    //await _subscription.cancel();
  }

  @override
  Future<void> resume() async {
    if (isCompleted) {
      onSuccess(taskResult!);
    } else if (!isRunning) {
      start = _uploadedByte;
      canceled = false;
      headers[gResuming] = _uploadedByte > 0 ? 'true' : null;
      await run();
    }
  }

  @override
  String? get result => taskResult;

  @override
  get id => _id;

// MediaType _mediaType(File file) {
//   return MediaType(
//       'application', path.extension(file.path).replaceRange(0, 1, '')
//   );
// }
}

abstract class Task extends IdentifiedTaskRunner with TaskState {
  late final String url;
  late int start;
  late int fileSize;
  late final File file;
  late final int retryCount;
  late final Duration retryDelay;
  @protected
  bool retrying = false;
  @protected
  String taskName = '';
  @protected
  int currentProgress = 0;
  @protected
  late int retryCountLeft;
  late StreamSubscription<List<int>> _subscription;
  late HttpClientRequest request;
  late final BadCertificateCallback badCertificateCallback;
  late final Map<String, dynamic> headers;

  CompletedTaskCallback _onSuccess = (d) {};
  AsyncCompletedTaskCallback _onError = (d, [bool retry = true]) async {};
  TaskProgressCallback? _onProgress;

  @protected
  late final String? taskResult;

  @protected
  bool runOnce = false;

  HttpClient getHttpClient({
    required BadCertificateCallback onBadCertificate,
    Duration connectionTimeOut = const Duration(seconds: 10),
  }) {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = connectionTimeOut
      ..badCertificateCallback = onBadCertificate;
    return httpClient;
  }

  @override
  Future<void> run() async {
    runOnce = true;
  }

  Future<void> _waitAndRetry(
      {required dynamic e,
      required CompletedTaskCallback onError,
      bool retry = true}) async {
    await Future.delayed(retryDelay, () async {
      await _retry(e: e, onError: onError, retry: retry);
    });
  }

  Future<void> _retry(
      {required dynamic e,
      required CompletedTaskCallback onError,
      bool retry = true}) async {
    if (retry && retryCountLeft > 0 && retryCount > 0 && !canceled) {
      retryCountLeft--;
      retrying = true;
      print('RETRYING $e');
      await resume();
    } else {
      onError.call(e);
    }
  }

  @override
  bool get isPaused => super.isPaused && !retrying;

  @override
  String get name => taskName;

  //Set onSuccess, onError and onProgressListener
  //It must be call before run and resume to not miss events
  void setListener(
      {required CompletedTaskCallback onSuccess,
      required CompletedTaskCallback onError,
      TaskProgressCallback? onProgress}) async {
    _onError = (e, [bool retry = true]) async {
      await _waitAndRetry(e: e, onError: onError, retry: retry);
    };
    _onSuccess = _onSuccess;
    _onProgress = onProgress;
  }

  @protected
  void resetRetryingCount() {
    if (retrying) {
      retrying = false;
    } else {
      retryCountLeft = retryCount;
    }
  }

  @override
  int get progress => currentProgress;

  @protected
  Future<void> stabilizeTask() async {}

  CompletedTaskCallback get onSuccess => _onSuccess;
  AsyncCompletedTaskCallback get onError => _onError;
  TaskProgressCallback? get onProgress => _onProgress;

  fileGetAllMock() {
    return List.generate(
      20,
      (i) => GUpDownMod(
          fileName: 'filename $i.jpg',
          dateModified: DateTime.now().add(Duration(minutes: i)),
          size: i * 1000),
    );
  }
  //
  // static Future<List<GUpDownMod>> fileGetAll() async {
  //   var httpClient = getHttpClient();
  //
  //   final url = '$baseUrl/api/file';
  //
  //   var httpRequest = await httpClient.getUrl(Uri.parse(url));
  //
  //   var httpResponse = await httpRequest.close();
  //
  //   var jsonString = await readResponseAsString(httpResponse);
  //
  //   return fileFromJson(jsonString);
  // }

  // static Future<String> fileDelete(String fileName) async {
  //   var httpClient = getHttpClient();
  //
  //   final url = Uri.encodeFull('$baseUrl/api/file/$fileName');
  //
  //   var httpRequest = await httpClient.deleteUrl(Uri.parse(url));
  //
  //   var httpResponse = await httpRequest.close();
  //
  //   var response = await readResponseAsString(httpResponse);
  //
  //   return response;
  // }

  static Future<String> responseAsString(HttpClientResponse response) {
    var completer = Completer<String>();
    var contents = StringBuffer();
    response.transform(utf8.decoder).listen((String data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }
}

List<GUpDownMod> fileFromJson(String str) {
  final jsonData = json.decode(str);
  return List<GUpDownMod>.from(jsonData.map((x) => GUpDownMod.fromJson(x)));
}

String fileToJson(List<GUpDownMod> data) {
  final dyn = List<dynamic>.from(data.map((x) => x.toJson()));
  return json.encode(dyn);
}

class GUpDownMod {
  String fileName;
  DateTime dateModified;
  int size;

  GUpDownMod({
    required this.fileName,
    required this.dateModified,
    required this.size,
  });

  factory GUpDownMod.fromJson(Map<String, dynamic> json) {
    //print( "Datum: ${json["dateModified"]}");

    return GUpDownMod(
      fileName: json["fileName"],
      dateModified: DateTime.parse(json["dateModified"]),
      size: json["size"],
    );
  }

  Map<String, dynamic> toJson() => {
        "fileName": fileName,
        "dateModified": dateModified,
        "size": size,
      };
}

Future<String> responseAsString(HttpClientResponse response) {
  var completer = Completer<String>();
  var contents = StringBuffer();
  response.transform(utf8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}


mixin TaskManagerMixin on LinkedTaskListener {

  @protected
  static late List<TaskBody> tasks;
  @protected
  static late List<TaskManagerListener> listeners;

  @protected
  Future<void> addTask(TaskBody task) async {
    task.addListener(this);
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
        element.dispose(this);
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

  @override
  void onCancel([id]) {
    _notifyCancelListener(id);
  }

  @override
  void onError([e, id]) {
    //print(e);
    _notifyErrorListener([e, id]);
  }

  @override
  void onPartialError([e, id]) {
    // TODO: implement onPartialError
  }

  @override
  void onPartialSuccess([result, id]) {
  }

  @override
  void onPause([id]) {
    _notifyPausedListener(id);
  }

  @override
  void onProgress(int percent, [id]) {
    _notifyProgressListener(percent, id);
  }

  @override
  void onResume([id]) {
    _notifyResumeListener(id);
  }

  @override
  void onSuccess([s, id]) {
    _notifySuccessListener(s, id);
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
  void onAnySuccess([result, id]);
  void onAnyTaskCanceled([id]) {}
  void onAnyTaskPaused([id]) {}
  void onAnyTaskResumed([id]) {}
  void onAnyError([e, id]) {}
  void onAnyCancel([id]) {}
  void onAnyProgress(int percent, id) {}
}
