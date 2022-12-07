import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

typedef OnDownloadProgressCallback = void Function(int receivedBytes,
    int totalBytes);

typedef OnUploadProgressCallback = void Function(int percent);
typedef TaskProgressCallback = void Function(int percent);
typedef CompletedTaskCallback = void Function(dynamic);


class DownloadTask extends Task {
  final String savePath;
  late FileMode fileMode;

  int _fileSize = -1;
  int _downloadedByte = 0;
  late File _file;
  bool _canBePaused = false;
  bool _canceled = false;
  bool _paused = false;
  bool _running = false;

  DownloadTask({
    required String url,
    required this.savePath,
    required this.fileMode,
    bool trustBadCertificate = false,
    int start = 0,
    Map<String, dynamic> headers = const {},
  }) {
    this.url = url;
    this.start = start;
    badCertificateCallback =
    ((X509Certificate cert, String host, int port) => trustBadCertificate);
    this.headers = headers;
  }

  factory DownloadTask.resume({
    required String url,
    required String savePath,
    required int start,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return DownloadTask(
        url: url,
        savePath: savePath,
        start: start,
        trustBadCertificate: trustBadCertificate,
        fileMode: FileMode.append,
        headers: headers
    );
  }

  factory DownloadTask.create({
    required String url,
    required String savePath,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) {
    return DownloadTask(
      url: url,
      savePath: savePath,
      trustBadCertificate: trustBadCertificate,
      fileMode: FileMode.write,
      headers: headers,
    );
  }

  static Future<DownloadTask> resumeFromFile({
    required String url,
    required String filePath,
    bool trustBadCertificate = false,
    Map<String, dynamic> headers = const {},
  }) async {
    File file = File(filePath);
    bool exists = await file.exists();
    int length = 0;
    if(exists) {
      length = await file.length();
    }

    return DownloadTask.resume(
      url: url,
      savePath: filePath,
      start: length,
      trustBadCertificate: trustBadCertificate,
      headers: headers,
    );
  }


  int get downloadedByte => _downloadedByte;
  bool get isRunning => _running;
  bool get isPaused => _paused;
  bool get isCanceled => _canceled;

  @override
  Future run({
    required CompletedTaskCallback onSuccess,
    required CompletedTaskCallback onError,
    TaskProgressCallback? onProgress
  }) async {
    final HttpClient httpClient = getHttpClient(
        onBadCertificate: badCertificateCallback
    );
    _running = true;
    _paused = false;

    try {
      request = await httpClient.getUrl(Uri.parse(url));
      request.headers..add(
          HttpHeaders.contentTypeHeader, "application/octet-stream")..add(
          HttpHeaders.rangeHeader, '$start');

      ///add user specific headers data
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });

      var httpResponse = await request.close();
      String errorMessage = httpResponse.reasonPhrase;

      if (!runOnce) {
        _fileSize = httpResponse.contentLength;
        runOnce = true;
      }

      if(httpResponse.statusCode == 200) {
        _file = File(savePath);

        var downloadedFile = _file.openSync(mode: fileMode);

        _subscription = httpResponse.listen((data) {
          _downloadedByte += data.length;

          downloadedFile.writeFromSync(data);

          onProgress?.call(((_downloadedByte / _fileSize) * 100).toInt());
        },
          onDone: () {
            downloadedFile.closeSync();
          },
          onError: (e) {
            downloadedFile.closeSync();
            _running = false;
            throw e;
          },
          cancelOnError: true,
        )
          ..onError((e) {
            onError('Connection error');
            _running = false;
          });

        _running = false;
        onSuccess(_file.path);

      } else {
        _running = false;
        await Task.responseAsString(httpResponse).then((value) => onError(value));
      }
    } on FileSystemException {
      onError('File system error');
    } on SocketException {
      onError('Host unreachable');
    } catch (e) {
      onError(e.toString());
    }
  }

  @override
  Future<void> cancel() async {
    _canceled = true;
    _paused = false;
    await _subscription.cancel();
    _running = false;
    request.abort();
    _file.deleteSync();
    start = 0;
    _downloadedByte = 0;
    fileMode = FileMode.write;
  }

  @override
  Future<bool> pause() async {
    if(!_canceled) {
      await _subscription.cancel();
      _paused = true;
      _running = false;
      request.abort();
    }
    return _paused;
  }

  @override
  Future<void> resume({
    required CompletedTaskCallback onSuccess,
    required CompletedTaskCallback onError,
    TaskProgressCallback? onProgress
  }) async {
    start = _downloadedByte;
    fileMode = FileMode.append;
    run(onSuccess: onSuccess, onError: onError, onProgress: onProgress);
  }


}

class UploadTask {
  //
  // Future<String> fileUpload(
  //     {required File file, OnUploadProgressCallback? onUploadProgress}) async {
  //
  //   final fileStream = file.openRead();
  //
  //   int totalByteLength = file.lengthSync();
  //
  //   final httpClient = getHttpClient(
  //       onBadCertificate: ((X509Certificate cert, String host, int port) => true)
  //   );
  //
  //   final request = await httpClient.postUrl(Uri.parse(url));
  //
  //   request.headers.set(HttpHeaders.contentTypeHeader, ContentType.binary);
  //
  //   request.headers.add("filename", path.basename(file.path));
  //   request.headers.add("multipart", '$multipart');
  //
  //   request.contentLength = totalByteLength;
  //
  //   int byteCount = 0;
  //   Stream<List<int>> streamUpload = fileStream.transform(
  //     StreamTransformer.fromHandlers(
  //       handleData: (data, sink) {
  //         byteCount += data.length;
  //
  //         if (onUploadProgress != null) {
  //           onUploadProgress(((byteCount / totalByteLength) * 100).toInt());
  //         }
  //
  //         sink.add(data);
  //       },
  //       handleError: (error, stack, sink) {
  //         print(error.toString());
  //       },
  //       handleDone: (sink) {
  //         sink.close();
  //         // UPLOAD DONE;
  //       },
  //     ),
  //   );
  //
  //   await request.addStream(streamUpload);
  //
  //
  //   final httpResponse = await request.close();
  //
  //   if (httpResponse.statusCode != 200) {
  //     throw Exception('Error uploading file');
  //   } else {
  //     return await Task.responseAsString(httpResponse);
  //   }
  // }

  static Future<void> fileUploadMultipart({
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
        onBadCertificate: ((X509Certificate cert, String host, int port) => true)
    );
    try {
      final request = await httpClient.postUrl(Uri.parse(url));

      int byteCount = 0;
      int percentage = 0;

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
              if (percentage != ((byteCount / totalByteLength) * 100).toInt()) {
                onProgress(((byteCount / totalByteLength) * 100).toInt());
                percentage = ((byteCount / totalByteLength) * 100).toInt();
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

  // static uploadFile({
  //   required String url,
  //   required File file,
  //   required void Function(String) onSuccess,
  //   required void Function(String) onError,
  //   Map<String, String> headers = const {}
  // }) async {
  //   var stream =
  //   http.ByteStream(file.openRead());
  //   // get file length
  //   var length = await file.length(); //imageFile is your image file
  //   int byteCount = 0; // ignore this headers if there is no authentication
  //
  //   // string to uri
  //   var uri = Uri.parse(url);
  //
  //   // create multipart request
  //   var request = http.MultipartRequest("POST", uri);
  //
  //   Stream<List<int>> streamUpload = stream.transform(
  //     StreamTransformer.fromHandlers(
  //       handleData: (data, sink) {
  //         sink.add(data);
  //
  //         byteCount += data.length;
  //
  //         // if (onUploadProgress != null) {
  //         //   if (percentage != ((byteCount / length) * 100).toInt()) {
  //         //     onUploadProgress(((byteCount / totalByteLength) * 100).toInt());
  //         //     percentage = ((byteCount / totalByteLength) * 100).toInt();
  //         //   }
  //         //   // CALL STATUS CALLBACK;
  //         // }
  //         print(((byteCount / length) * 100).toInt());
  //       },
  //       handleError: (error, stack, sink) {
  //         throw error;
  //       },
  //       handleDone: (sink) {
  //         sink.close();
  //         // UPLOAD DONE;
  //       },
  //     ),
  //   );
  //
  //
  //   // multipart that takes file
  //   var multipartFileSign =  http.MultipartFile('profile_pic', streamUpload, length,
  //       filename: 'big2.avi');
  //
  //   // add file to multipart
  //   request.files.add(multipartFileSign);
  //
  //   Map<String, String> header = {
  //
  //   };
  //
  //   header[HttpHeaders.contentTypeHeader] = 'application/octet-stream';
  //   header['file_name'] = 'big2.avi';
  //   header.addAll(headers);
  //   //add headers
  //   request.headers.addAll(header);
  //
  //   //adding params
  //   request.fields['loginId'] = '12';
  //   request.fields['firstName'] = 'abc';
  //   // request.fields['lastName'] = 'efg';
  //
  //   try {
  //     // send
  //     var response = await request.send();
  //
  //     print(response.statusCode);
  //     if (response.statusCode ~/ 100 != 2) {
  //       response.stream.transform(utf8.decoder).listen((value) {
  //         onError(value);
  //       });
  //     } else {
  //       // listen for response
  //       response.stream.transform(utf8.decoder).listen((value) {
  //         onSuccess(value);
  //       });
  //     }
  //
  //   } catch (e) {
  //     onError(e.toString());
  //   }
  // }

  static Future<void> uploadImage({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    required String destination,
    Map<String, String> headers = const {},
    OnUploadProgressCallback? onProgress,
  }) async {
    return fileUploadMultipart(
        onSuccess: onSuccess,
        onError: onError,
        file: file,
        destination: destination,
        headers: headers,
        onProgress: onProgress,
        mediaType: MediaType(
            'image', path.extension(file.path).replaceRange(0, 1, '')));
  }

  static Future<void> uploadDoc({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    required String destination,
    Map<String, String> headers = const {},
    OnUploadProgressCallback? onProgress,
  }) async {
    return fileUploadMultipart(
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


// MediaType _mediaType(File file) {
//   return MediaType(
//       'application', path.extension(file.path).replaceRange(0, 1, '')
//   );
// }


}

abstract class Task {

  late final String url;
  late int start;
  late StreamSubscription<List<int>> _subscription;
  late HttpClientRequest request;
  late final BadCertificateCallback badCertificateCallback;
  late final Map<String, dynamic> headers;

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

  Future run({
    required CompletedTaskCallback onSuccess,
    required CompletedTaskCallback onError,
    TaskProgressCallback? onProgress
  }) async {
    runOnce = true;
  }

  void pause();

  void resume({
    required CompletedTaskCallback onSuccess,
    required CompletedTaskCallback onError,
    TaskProgressCallback? onProgress
  });

  void cancel();

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
