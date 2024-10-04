import 'package:flutter/material.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.userName, required this.id});
  final String userName;
  final String id;

  @override
  State<SettingPage> createState() => SettingState();
}

class SettingState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('지역 변경하기: 팝업으로 할 거임.')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('회원정보수정?')),
          ],
        ),
      ),
    );
  }
}
