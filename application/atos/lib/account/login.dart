//로그인 페이지

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

//로그인 버튼을 눌렀을 때
  Future<void> signInWithEmailAndPassword() async {
    try {
      //auth를 사용해서 로그인
      await firebaseAuth.signInWithEmailAndPassword(
        email: '$id@example.com',
        password: password,
      );

      //로그인 api: 로그인 기록 남기기.
      http.get(
        Uri.parse('${ControlUri.BASE_URL}/login/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        title: const Text('로그인'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  borderSide: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                constraints: BoxConstraints(
                  maxHeight: 50.0,
                  maxWidth: 250.0,
                ),
              ),
              onChanged: (text) {
                id = text;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  borderSide: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                constraints: BoxConstraints(
                  maxHeight: 50.0,
                  maxWidth: 250.0,
                ),
              ),
              onChanged: (text) {
                password = text;
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: signInWithEmailAndPassword,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('로그인'),
            ),
            if (loginFailed)
              const Text(
                '아이디 혹은 비밀번호가 올바르지 않습니다.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
