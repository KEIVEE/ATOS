import 'package:flutter/material.dart';
import 'package:atos/managing/manage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  final String loginTitle = '로그인';

  @override
  State<LoginPage> createState() => LoginState();
}

class LoginState extends State<LoginPage> {
  var id = "";
  var password = "";
  var loginTried = false;
  var userName = "";
  var loginFailed = false;

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
                }),
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
                  )),
              onChanged: (text) {
                password = text;
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: "/manage"),
                    builder: (context) =>
                        ManagePage(userName: userName, id: id),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
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
