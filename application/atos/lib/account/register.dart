import 'package:flutter/material.dart';

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
  var testUrl = "";
  String idCheckMessage = ""; // ID 중복 확인 메시지 저장 변수
  var idChecked = false;
  var registerTried = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
        title: Text(widget.loginTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 50.0,
                    maxWidth: 250.0,
                  )),
              onChanged: (text) {
                nickname = text;
              },
            ),
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
                  )),
              onChanged: (text) {
                id = text;
                testUrl = 'http://211.201.203.110:9000/api/user/check/$id';
              },
            ),
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('아이디 확인'),
            ),
            Text(
              idCheckMessage,
              style: TextStyle(
                color: idCheckMessage == '사용할 수 없는 id입니다.'
                    ? Colors.red
                    : Colors.green,
              ),
            ),
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
                  )),
              onChanged: (text) {
                password = text;
              },
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 50.0,
                    maxWidth: 250.0,
                  )),
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
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('가입하기'),
            ),
            if (!correction && registerTried)
              const Text(
                '비밀번호가 일치하지 않습니다.',
                style: TextStyle(color: Colors.red),
              ),
            const Text('지역 선택하는 부분')
          ],
        ),
      ),
    );
  }
}
