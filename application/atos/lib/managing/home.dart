//오늘의 문장, 잔디심기(깃허브에 있는거처럼), 설정 버튼을 가진 화면
//login.dart에서 로그인 기록을 저장하는 이유가 잔디심기임

import 'package:atos/control/ui.dart';
import 'package:flutter/material.dart';
import 'package:atos/account/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.id});
  final String id;

  @override
  State<HomePage> createState() => HomeState();
}

class HomeState extends State<HomePage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  var connected = false;
  var connectTried = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: "/settiing"),
                            builder: (context) => SettingPage(id: widget.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ), // Add spacing to avoid overlap
              const Text('오늘의 추천 문장:', style: TextStyle(color: Colors.white)),
              const Text('오늘의 추천 문장이 없습니다.',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 10),
              CustomedButton(
                text: '시도하기',
                buttonColor: Colors.white,
                textColor: Theme.of(context).primaryColor,
                onTap: () {
                  // 시도하기: 그냥 쉬움
                },
              ),
              const SizedBox(height: 20),
              ManageSizedBox(
                  content: Column(
                    children: [
                      const Text('잔디심기 부분',
                          style: TextStyle(fontSize: 30, height: 3)),
                    ],
                  ),
                  boxHeight: 547)
            ],
          ),
        ),
      ),
    );
  }
}
