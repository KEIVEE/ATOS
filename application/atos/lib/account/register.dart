import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  final String loginTitle = '회원가입';

  @override
  State<RegisterPage> createState() => RegisterState();
}

class RegisterState extends State<RegisterPage> {
  var nickname = "";
  var id = "";
  var password = "";
  var passwordCheck = "";
  var correction = true;
  String idCheckMessage = ""; // ID availability message
  String registerCheckMessage = "";
  var idChecked = false;
  var registerTried = false;
  final regions = ['경상도', '전라도', '충청도', '강원도', '제주도'];

  Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  var region = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ID check function
  Future<void> checkIdAvailability() async {
    if (id.isEmpty) {
      setState(() {
        idCheckMessage = "아이디를 입력해주세요.";
      });
      return;
    }

    try {
      final signInMethods =
          await _auth.fetchSignInMethodsForEmail('$id@example.com');
      setState(() {
        idChecked = signInMethods.isEmpty;
        idCheckMessage = idChecked ? '사용할 수 있는 id입니다.' : '사용할 수 없는 id입니다.';
      });
    } catch (e) {
      setState(() {
        idCheckMessage = '사용할 수 있는 id입니다.';
      });
    }
  }

  Future<void> registerUser() async {
    setState(() {
      registerTried = true;
    });

    if (!correction || !idChecked || id.isEmpty || password.isEmpty) {
      return;
    }

    // 비밀번호 길이 검사
    if (password.length < 6) {
      setState(() {
        registerCheckMessage = '비밀번호는 6자 이상이어야 합니다.';
      });
      return;
    }

    try {
      // Firebase Auth로 사용자 생성

      http.Response response = await http.post(
          Uri.parse('http://222.237.88.211:8000/set-user'),
          body: json.encode({'user_id': id, 'region': region, 'sex': "male"}),
          headers: headers);

      if (response.statusCode != 200) {
        debugPrint("회원가입 오류.");
      }

      await _auth.createUserWithEmailAndPassword(
        email: '$id@example.com',
        password: password,
      );
      _auth.currentUser?.updateDisplayName(nickname);
      //_auth.currentUser?.updatePhotoURL(region);

      if (mounted) {
        Navigator.pop(context); // 성공적으로 회원가입이 완료되면 뒤로 이동
      }
    } catch (e) {
      setState(() {
        registerCheckMessage = '회원가입 중 오류가 발생했습니다: ${e.toString()}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      region = regions[0];
    });
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
        title: Text(widget.loginTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Nickname field
            TextField(
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxHeight: 50.0, maxWidth: 250.0),
              ),
              onChanged: (text) {
                nickname = text;
              },
            ),

            // ID field and check button
            TextField(
              decoration: const InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxHeight: 50.0, maxWidth: 250.0),
              ),
              onChanged: (text) {
                id = text;
              },
            ),
            OutlinedButton(
              onPressed: checkIdAvailability,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('아이디 확인'),
            ),
            Text(
              idCheckMessage,
              style: TextStyle(
                color: idCheckMessage == '사용할 수 있는 id입니다.'
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            // Password fields
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxHeight: 50.0, maxWidth: 250.0),
              ),
              onChanged: (text) {
                password = text;
              },
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxHeight: 50.0, maxWidth: 250.0),
              ),
              onChanged: (text) {
                setState(() {
                  passwordCheck = text;
                  correction = password == passwordCheck;
                });
              },
            ),
            if (!correction)
              const Text(
                '비밀번호가 일치하지 않습니다.',
                style: TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 20),

            DropdownButton(
                value: region,
                items: regions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    region = value!;
                  });
                }),

            // Register button
            OutlinedButton(
              onPressed: registerUser,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('가입하기'),
            ),

            Text(
              registerCheckMessage,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
