//다시 연습한 결과를 보여주는 페이지
//미완성. 하지만 show.dart와 같은 역할을 함

import 'package:flutter/material.dart';

class TryResultPage extends StatefulWidget {
  const TryResultPage({super.key, required this.id});
  final String id;

  @override
  State<TryResultPage> createState() => TryResultState();
}

class TryResultState extends State<TryResultPage> {
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
                child: const Text('홈으로 가기')),
            OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) {
                    return route.settings.name == '/content'; // HomePage의 경로
                  });
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('연습으로 돌아가기')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('다시? 아니면 저장하지 않기?')),
            const Text('양옆으로 바꿀 거임. 아니면 양옆 늘려서 이대로 가던가, 아이콘으로 바꾸던가?'),
          ],
        ),
      ),
    );
  }
}
