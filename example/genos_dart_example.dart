import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:genos_dart/genos_dart.dart';
import 'package:uuid/uuid.dart';

void main() async {
  dudExample();
  //
  // String str = "CEci est le string";
  // String en = Auth.encodeBase64String(str);
  // print(str.length);
  // print(en.length);
  // en = Auth.encodeBase64String(en);
  // print(en);
  // en = Auth.encodeBase64String(en);
  // print(en);
  // en = Auth.encodeBase64String(en);
  // print(en);
  // print(Auth.decodeBase64String(en));

  // await Genos.instance.initialize(
  //     appSignature: '91a2dbf0-292d-11ed-91f1-4f98460f463c',
  //     appWsSignature: '91a2dbf0-292d-11ed-91f1-4f98460f464c',
  //     appPrivateDirectory: '.',
  //     encryptionKey: '91a2dbf0-292d-11ed-91f1-4f98460d',
  //     host: 'localhost',
  //     port: '8080',
  //     unsecurePort: '80',
  //     onInitialization: (Genos g) async {
  //       // await Genos.auth.loginWithQRCode(
  //       //   secure: false,
  //       //     onSuccess: (User u) {
  //       //       print('SUCCESS');
  //       //       print(u);
  //       //     },
  //       //     onCodeReceived: (String code) async {
  //       //     ///await Future.delayed(Duration(minutes: 11));
  //       //       await Genos.auth.confirmQrCode(
  //       //         secure: false,
  //       //           qrCodeData: code,
  //       //           user: User(email: 'nono', uid: 'oiea'),
  //       //           onSuccess: () {
  //       //           print('ON SUCCESS');
  //       //           },
  //       //           onError: (String e) {
  //       //             print("Confirmation error $e");
  //       //           });
  //       //     },
  //       //     onError: (String e) {
  //       //       print('Login error $e');
  //       //     },
  //       //     platform: 'Linux',
  //       //     onDetached: (String e) {
  //       //     print('detached $e');
  //       //     }
  //       // );
  //       String table = 'users';
  //       await GDirectRequest.select(
  //           sql: 'SELECT * FROM $table'
  //       ).exec(
  //         secure: false,
  //           onSuccess: (Result result) {
  //             if(result.data.isNotEmpty) {
  //               //result.data is a list of list so we retrieve the first element
  //               //which is a list with table colum number as length
  //               //List myData = result.data;
  //               List<Map<String, dynamic>>  myData = result.data;
  //               print(myData);
  //             }
  //           },
  //           onError: (RequestError e) {
  //             print('ERROR $e');
  //           });
  //
  //     }
  // );

  //Listen to specific table with specific value
  // DataListener l = DataListener(
  //     table: 'company',
  //     tag: '127af730-5b60-11ed-8f30-152c420dff9f'
  // );
  // l.listen(() {
  //   print('changed');
  // },
  //     onError: (e) {
  //       print('On ERROR 1');
  //     },
  //     secure: false
  // );
// Auth auth = await Auth.instance;
  // if(auth.user != null) {
  //   print(auth.user!.toString());
  // } else {
  //   print('unauthenticated user');
  // }

  // DataListener(table: 'company').listen(() {
  //   print('changed');
  // },
  //     onError: (e) {
  //   print('On ERROR 2');
  // },
  //   secure: false
  // );
  //
  // DataListener(table: 'company', tag: 'wi').listen(() {
  //   print('changed');
  // },
  //     onError: (e) {
  //   print('On ERROR 3');
  //     },
  //     secure: false
  // );
  //print(auth.user.toString());
  // auth.loginWithEmailAndPassword(
  //   secure: false,
  //     email: 'stevenalandou@gmail.com',
  //     password: '4fd4d',
  //     onSuccess: (User user) {
  //       print("SUCCESS");
  //       print(user.uid);
  //     },
  //     onError: (e) {
  //   print(e);
  // });

  // auth.loginWithPhoneNumber(
  //   secure: false,
  //     phoneNumber: '+228 98882061',
  //     onSuccess: (u) {
  //       print('SUCCESS');
  //     },
  //     onError: (e) {
  //       print(e.toString());
  //     });
  // auth.changePhoneNumber(
  //   secure: false,
  //     phoneNumber: '98882061',
  //     newPhoneNumber: '93359228',
  //     onSuccess: () {
  //       print('SUCCESS');
  //     },
  //     onError: (e) {
  //       print('ERROR $e');
  //     });
  // auth.changePassword(
  //   secure: false,
  //     email: 'tgrecycleinc@gmail.com',
  //     password: 'passoir]',
  //     newPassword: 'passoir',
  //     onSuccess: (){
  //       print('success');
  //     },
  //     onError: (e) {
  //       print(e);
  //     }
  // );
  // auth.recoverPassword(
  //   secure: false,
  //     email: 'tgrecycleinc@gmail.com',
  //     onSuccess: () {
  //       print('success');
  //     },
  //     onError: (e) {
  //       print(e);
  //     }
  // );
  // auth.signingWithEmailAndPassword(
  //   secure: false,
  //   email: 'serge@miaplenou.com',
  //   password: '12413',
  //   onListenerDisconnected: (e) {
  //     print(e);
  //   },
  //   onEmailConfirmed: (User u) {
  //     print('CONFIRMED');
  //   },
  //   onEmailSent: () {
  //     print('EMAIL SENT');
  //   },
  //   onError: (e) {
  //     print('ERROR');
  //     print(e);
  //   },
  // );
  // auth.changeEmail(
  //   secure: false,
  //   newEmail: 'stevenalandou@gmail.com',
  //   oldEmail: 'stmerlhin@gmail.com',
  //   password: 'password',
  //   onListenerDisconnected: (e) {
  //     print(e);
  //   },
  //   onEmailConfirmed: () {
  //     print('CONFIRMED');
  //   },
  //   onEmailSent: () {
  //     print('EMAIL SENT');
  //   },
  //   onError: (e) {
  //     print('ERROR');
  //     print(e);
  //   },
  // );
}

void dudExample() async {
  List<DownloadTaskWrapper> tas = [
    DownloadTaskWrapper(
        downloadTask: DownloadTask.resumeFromFile(
          id: 1,
          url: 'https://www.hq.nasa.gov/alsj/a17/A17_FlightPlan.pdf',
          filePath: 'apolo11.pdf',
          trustBadCertificate: true,
          //headers: {'app_signature': '91a2dbf0-292d-11ed-91f1-4f98460f463c'}
          // )
        )
    ),
    DownloadTaskWrapper(
        downloadTask: DownloadTask.resumeFromFile(
          id: 2,
          url: 'https://www.hq.nasa.gov/alsj/a17/A17_FlightPlan.pdf',
          filePath: 'apolo12.pdf',
          trustBadCertificate: true,
          //headers: {'app_signature': '91a2dbf0-292d-11ed-91f1-4f98460f463c'}
          // )
        )
    ),
    DownloadTaskWrapper(
        downloadTask: DownloadTask.resumeFromFile(
      id: 3,
      url: 'http://192.168.1.77/big2.mp4',
      filePath: 'apolo.mp4',
      trustBadCertificate: true,
      //headers: {'app_signature': '91a2dbf0-292d-11ed-91f1-4f98460f463c'}
      // )
    )),
  ];

  LinkedTasksWrapper wrapper = LinkedTasksWrapper(tas);
  wrapper.addListener(LinkedTaskListenerCallbacks(onSuccessCalled: ([value, id]) {
    print('SUCCESS CALLED');
  }, onErrorCalled: (str, [id]) {
    print('ON ERROR');
    print(str);
  }, onProgressCalled: (p, [id]) {
    print(p);
  }, onPartialSuccessCalled: (i, v) {
    print('PARTIAL SUCCESS ${wrapper.tasksLeft} $i $v');
    // wrapper.cancel();
  }));
  // d.setListener(onProgress: (pr) async {
  //   // if(pr == 50) {
  //   //   await d.pause();
  //   //   print(d.isRunning);
  //   //   print('paused ${d.downloadedByte}');
  //   // }
  //   print('$pr% ');
  //   // if(pr >= 50) {
  //   //   print('pausing');
  //   //   d.pause();
  //   // }
  // }, onSuccess: (str) {
  //   print(str);
  // }, onError: (str) {
  //   print('THIS IS AN ERROR');
  //   print(str);
  // });

  await wrapper.run();
  print("So this is a mess");
  //
  // Timer(Duration(seconds: 5), () {
  //   print('RESUMING');
  //   d.resume(onProgress: (pr) async {
  //     print('$pr% ${d.isRunning}');
  //   },
  //       onSuccess: (str) {
  //         print('success');
  //         print(str);
  //       }, onError: (str) {
  //         print(str);
  //       });
  // });
  //
  // var up = UploadTask.create(
  //     file: File('big2.mp4'),
  //     url: 'http://localhost/upload/1/mediathec',
  //     headers: {
  //       gFileName: "average.mp4",
  //       gAppSignature: '91a2dbf0-292d-11ed-91f1-4f98460f463c',
  //     });
  //
  // await up.run(
  //     onProgress: (pr) {
  //       print(pr);
  //       if(pr >= 50) {
  //         print('pausing');
  //         try {
  //           up.cancel();
  //         } catch(e) {
  //           print('FRF $e');
  //         }
  //       }
  //     },
  //     onSuccess: (String url) {
  //       print(url);
  //     },
  //     onError: (e) {
  //       print(e);
  //     }
  // );
  // Timer(Duration(seconds: 5), () {
  //   print('RESUMING');
  //   up.resume(
  //       onProgress: (pr) {
  //         print('$pr%');
  //       },
  //       onSuccess: (str) {
  //         print('success');
  //         print(str);
  //       }, onError: (str) {
  //     print(str);
  //   });
  // });
  // print('one moment');
}
