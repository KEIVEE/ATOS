import 'package:flutter/material.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class ShowPage extends StatefulWidget {
  const ShowPage({super.key, required this.id});
  final String id;

  @override
  State<ShowPage> createState() => ShowState();
}

class ShowState extends State<ShowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결과'),
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
            const Text('그래프'),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('표준어 듣기')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('내 발음 듣기')),
            OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) {
                    return route.settings.name == '/manage'; // HomePage의 경로
                  });
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('홈으로 가기 = 연습목록에 추가하지 않기')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('연습목록에 추가')),
            const Text('양옆으로 바꿀 거임. 아니면 양옆 늘려서 이대로 가던가, 아이콘으로 바꾸던가?'),
          ],
        ),
      ),
    );
  }
}
