//로그인 페이지

import 'package:atos/control/ui.dart';
import 'package:flutter/material.dart';
import 'package:atos/managing/manage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:atos/control/uri.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginState();
}

class LoginState extends State<LoginPage> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  var id = ""; // ID
  var password = ""; // 비밀번호
  var loginTried = false; // 로그인 시도 여부
  var loginFailed = false; // 로그인 실패 여부

  Future<void> getToken() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      ControlUri.TOKEN = await user.getIdToken();
      debugPrint('JWT Token: ${ControlUri.TOKEN}');
    } else {
      //print('User is not logged in.');
    }
  }

//로그인 버튼을 눌렀을 때
  Future<void> signInWithEmailAndPassword() async {
    try {
      //auth를 사용해서 로그인
      await firebaseAuth.signInWithEmailAndPassword(
        email: '$id@example.com',
        password: password,
      );

      await getToken();

      //로그인 api: 로그인 기록 남기기.
      http.get(
        Uri.parse('${ControlUri.BASE_URL}/login/$id'),
        headers: ControlUri.headerUtf8,
      );

      //로그인 성공 시 로그인 실패 메시지 제거
      setState(() {
        loginFailed = false;
      });

      //관리 페이지로
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: "/manage"),
            builder: (context) => ManagePage(id: id),
          ),
        );
      }
    } catch (e) {
      // 로그인 실패 시 메시지 표시
      setState(() {
        loginFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: ShortInputText(hint: 'ID를 입력해 주세요.'),
              onChanged: (text) {
                id = text;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ObscuringTextEditingController(),
              decoration: ShortInputText(hint: '비밀번호를 입력해 주세요.'),
              onChanged: (text) {
                password = text;
              },
            ),
            const SizedBox(height: 20),
            CustomedButton(
              text: '로그인',
              buttonColor: const Color.fromRGBO(42, 52, 110, 1),
              textColor: Colors.white,
              onTap: () {
                setState(() {
                  loginTried = true;
                });
                signInWithEmailAndPassword();
              },
            ),
            if (loginFailed)
              const Text(
                '아이디 혹은 비밀번호가 올바르지 않습니다.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    ));
  }
}
