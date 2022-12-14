

import 'dart:convert';

import 'package:genos_dart/genos_dart.dart';
import 'package:genos_dart/src/utils/dud.dart';
import 'package:uuid/uuid.dart';

void main() async {

  await Genos.instance.initialize(
      appSignature: '91a2dbf0-292d-11ed-91f1-4f98460f463c',
      appWsSignature: '91a2dbf0-292d-11ed-91f1-4f98460f464c',
      appPrivateDirectory: '.',
      encryptionKey: '91a2dbf0-292d-11ed-91f1-4f98460d',
      host: 'localhost',
      port: '8080',
      unsecurePort: '80',
      onInitialization: (Genos g) async {
        // await Genos.auth.loginWithQRCode(
        //   secure: false,
        //     onSuccess: (User u) {
        //       print('SUCCESS');
        //       print(u);
        //     },
        //     onCodeReceived: (String code) async {
        //     ///await Future.delayed(Duration(minutes: 11));
        //       await Genos.auth.confirmQrCode(
        //         secure: false,
        //           qrCodeData: code,
        //           user: User(email: 'nono', uid: 'oiea'),
        //           onSuccess: () {
        //           print('ON SUCCESS');
        //           },
        //           onError: (String e) {
        //             print("Confirmation error $e");
        //           });
        //     },
        //     onError: (String e) {
        //       print('Login error $e');
        //     },
        //     platform: 'Linux',
        //     onDetached: (String e) {
        //     print('detached $e');
        //     }
        // );
        String table = 'users';
        await GDirectRequest.select(
            sql: 'SELECT * FROM $table'
        ).exec(
          secure: false,
            onSuccess: (Result result) {
              if(result.data.isNotEmpty) {
                //result.data is a list of list so we retrieve the first element
                //which is a list with table colum number as length
                List myData = result.data.first;
                print(myData);
              }
            },
            onError: (RequestError e) {
              print('ERROR $e');
            });

      }
  );

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
  DownloadTask d = DownloadTask.create(
      url: 'http://localhost/download/logo/07099bf0-44d0-11ed-9eed-8be08643a4a6.jpg',
      savePath: 'cache/photo.jpg',
      trustBadCertificate: true,
      headers: {
        'app_signature': '91a2dbf0-292d-11ed-91f1-4f98460f463ch'
      }
  );

  await d.run(
      onProgress: (pr) async {
        // if(pr == 50) {
        //   await d.pause();
        //   print(d.isRunning);
        //   print('paused ${d.downloadedByte}');
        // }
        print('$pr% ${d.isRunning}');
      },
      onSuccess: (str) {
        print(str);
      },
      onError: (str) {
        print(str);
      });

  // Timer(Duration(seconds: 10), () {
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

  // UploadTask.uploadDoc(
  //     headers: {
  //       "file_name": "big2.avi",
  //       "app_signature": '91a2dbf0-292d-11ed-91f1-4f98460f463c',
  //       "the_mime": "application/avi"
  //     },
  //     file: File('big2.avi'),
  //     destination: 'http://localhost/upload/contracts',
  //     onProgress: (progress) {
  //       print(progress);
  //     },
  //     onSuccess: (url) {
  //       print(url);
  //     },
  //     onError: (e) {
  //       print(e);
  //     });

  // await UploadTask.uploadFile(
  //     url: 'http://localhost:80/upload/contracts',
  //   onSuccess: (str) {
  //       print(str);
  //   },
  //   onError: (e) {
  //       print(e);
  //   }
  // );

  print('one moment');
}
