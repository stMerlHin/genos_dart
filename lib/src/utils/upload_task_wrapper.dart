import '../../genos_dart.dart';

class UploadTaskWrapper extends TaskWrapper {
  UploadTaskWrapper({required UploadTask uploadTask, String name = ''}) {
    task = uploadTask;
  }
}
