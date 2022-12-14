
<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

Useful example in `/example` folder. 

Add genos_dart to pubspec.yaml file as dependency

```yaml
dependencies:
  genos_dart:
    git:
      url: https://github.com/stMerlHin/genos_dart.git
      ref: merlhin-dev
```

First initialize the genos client

```dart
await Genos.instance.initialize(
appSignature: '91a2dbf0-292d-11ed-91f1-4f98460f463c',
appWsSignature: '91a2dbf0-292d-11ed-91f1-4f98460f464c',
appPrivateDirectory: '.',
encryptionKey: '91a2dbf0-292d-11ed-91f1-4f98460d',
//THE DATABASE SERVER
host: 'localhost',
port: '8080',
unsecurePort: '80',
onInitialization: (g) async {

//DO SOMETHING ONCE THE INITILIZATION COMPLETED

}
);
```
Make Select query

```dart
String table = 'client';
  GDirectRequest.select(
      sql: 'SELECT * FROM $table'
  ).exec(
    //
      onSuccess: (Result result) {
        if(result.data.isNotEmpty) {
          //result.data is a list of Map<String, dynamic> so we retrieve the first element 
          //which is a map with table colum name as key
          Map<String, dynamic> myData = result.data.first;
          //Get all data
          List<Map<String, dynamic>> myData = result.data;
        }
      },
      onError: (RequestError e) {
        print('ERROR ${e.code} ${e.message}');
      });
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
