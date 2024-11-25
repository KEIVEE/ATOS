//다시 연습하는 페이지
//미완성. 하지만 translated.dart와 하는 역할이 비슷함

import 'package:flutter/material.dart';

class TryPage extends StatefulWidget {
  const TryPage({super.key, required this.id});
  final String id;

  @override
  State<TryPage> createState() => TryState();
}

class TryState extends State<TryPage> {
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
            const Text('다시 시도하기'),
            const Text('"문장."'),
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
                child: const Text('다시 녹음')),
            OutlinedButton(
              onPressed: null,
              /*() {
                // 아이콘을 눌렀을 때 AnalyzingPage로 5초 동안 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: "/analyzing"),
                    builder: (context) => AnalyzingPage(
                        duration: const Duration(seconds: 3),
                        userName: widget.userName,
                        id: widget.id,
                        previousPageName: 'TryPage'),
                  ),
                );
              },*/
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('분석 시작'),
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.circle, color: Colors.red),
              iconSize: 80,
            ),
            const Text('양옆으로 바꿀 거임. 아니면 녹음 화면을 따로 만들던가?'),
          ],
        ),
      ),
    );
  }
}
