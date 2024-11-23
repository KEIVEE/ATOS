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

  var id = "";
  var password = "";
  var loginTried = false;
  var loginFailed = false;

  Future<void> signInWithEmailAndPassword() async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: '$id@example.com',
        password: password,
      );

      http.get(
        Uri.parse('${ControlUri.BASE_URL}/login/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      // 로그인 성공 시, 사용자 이름을 설정하고 페이지 이동
      setState(() {
        loginFailed = false;
      });
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
