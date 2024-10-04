import 'package:flutter/material.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class AnalyzingPage extends StatefulWidget {
  const AnalyzingPage({super.key});

  @override
  State<AnalyzingPage> createState() => AnalyzingState();
}

class AnalyzingState extends State<AnalyzingPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('분석중이에요'),
            CircularProgressIndicator(
              strokeWidth: 40,
            ),
          ],
        ),
      ),
    );
  }
}
