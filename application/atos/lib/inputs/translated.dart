import 'package:flutter/material.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class TranslatedPage extends StatefulWidget {
  const TranslatedPage({super.key, required this.userName, required this.id});
  final String userName;
  final String id;

  @override
  State<TranslatedPage> createState() => TranslatedState();
}

class TranslatedState extends State<TranslatedPage> {
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
            const Text('변환된 문장이에요'),
            const Text('"변환된 문장."'),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('표준어 듣기')),
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
