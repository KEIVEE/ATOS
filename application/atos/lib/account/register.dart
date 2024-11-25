//회원가입하는 화면

import 'dart:convert';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atos/account/voiceregister.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  final String loginTitle = '회원가입';

  @override
  State<RegisterPage> createState() => RegisterState();
}

class RegisterState extends State<RegisterPage> {
  var nickname = ""; // 닉네임
  var id = ""; // ID
  var password = ""; // 비밀번호
  var passwordCheck = ""; // 비밀번호 확인
  var correction = true; // 비밀번호 일치 여부
  String idCheckMessage = ""; // ID availability message
  String registerCheckMessage = ""; // 등록할 때 까먹은 부분이 무엇인지.
  var idChecked = false; // ID 중복 확인 여부
  var registerTried = false; // 회원가입 시도 여부
  final regions = ['경상도', '전라도', '충청도', '강원도', '제주도']; // 지역 목록
  String selectedGender = "남성"; // 성별을 저장할 변수 (기본값: 남성)

  Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  var region = ""; // 지역

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ID 중복 체크 버튼
  Future<void> checkIdAvailability() async {
    if (id.isEmpty) {
      // 아이디를 입력하지 않은 경우 아이디 확인 버튼 누를 때 메세지가 뜨도록
      setState(() {
        idCheckMessage = "아이디를 입력해주세요.";
      });
      return;
    }

    try {
      final signInMethods = await _auth
          .fetchSignInMethodsForEmail('$id@example.com'); // 이메일 형식이 아니면 등록이 안됨.
      //example.com은 임시로 쓰지만, 가입을 이메일로 받을 수도 있음.
      setState(() {
        idChecked = signInMethods
            .isEmpty; //아이디 중복 확인 버튼을 눌렀을 때 중복이면 false, 중복이 아니면 true
        idCheckMessage = idChecked ? '사용할 수 있는 id입니다.' : '사용할 수 없는 id입니다.';
      });
    } catch (e) {
      //이유는 모르겠으나 사용할 수 있는 id일 때 익셉션이 발생. 사용할 수 없는거만 거르면 되니까 무시하도록 핸들링
      setState(() {
        idCheckMessage = '사용할 수 있는 id입니다.';
      });
    }
  }

  // 회원가입 버튼
  Future<void> registerUser() async {
    //회원가입 시도를 했다는 표시.
    //왜 필요하냐면, 회원가입 시도를 하지 않은 상태에서 회원가입 오류 메시지기 뜨지 않게 하기 위함임
    //이걸 누르면 메시지가 뜨도록
    setState(() {
      registerTried = true;
    });

    if (!correction || !idChecked || id.isEmpty || password.isEmpty) {
      //조건들이 필요한데, 비밀번호가 일치해야 하고, 아이디 중복 확인이 되어야 하고, 아이디와 비밀번호가 비어있으면 안됨.
      return;
    }

    // 비밀번호 길이 검사
    if (password.length < 6) {
      setState(() {
        //비밀번호가 6자 이상이라는 것은 firebase에서 정한 규칙임
        registerCheckMessage = '비밀번호는 6자 이상이어야 합니다.';
      });
      return;
    }

    try {
      // Firebase Auth로 사용자 생성
      //추가 정보를 저장하기 위해 post를 함.
      //post를 먼저 하는 이유는 auth를 먼저 만들어버리면 http오류가 났을 때도
      //사용자가 등록되는 문제가 있음

      http.Response response = await http.post(
          Uri.parse('${ControlUri.BASE_URL}/set-user'),
          body: json
              .encode({'user_id': id, 'region': region, 'sex': selectedGender}),
          headers: headers);

      if (response.statusCode != 200) {
        debugPrint("회원가입 오류.");
      }

//auth에 유저 등록하기
      await _auth.createUserWithEmailAndPassword(
        email: '$id@example.com',
        password: password,
      );
      //닉네임은 auth의 유저 클래스에 저장
      _auth.currentUser?.updateDisplayName(nickname);
      //_auth.currentUser?.updatePhotoURL(region);

      if (mounted) {
        //회원가입은 완료됐는데, 등록해야 할 것이 있음.
        //필터링을 잘 하기 위해 최저 목소리, 최고 목소리를 등록해야 함.
        //최저 목소리, 최고 목소리 등록 페이지로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: "/voiceRegister"),
            builder: (context) => VoiceRegisterPage(id: id),
          ),
        );
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
            DropdownButton<String>(
              value: selectedGender,
              items: <String>['남성', '여성'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedGender = newValue!;
                });
              },
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
