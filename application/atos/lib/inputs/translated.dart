import 'package:flutter/material.dart';
import 'analyzing.dart';

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
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              '변환된 문장이에요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '"변환된 문장."',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                // 아이콘을 눌렀을 때 AnalyzingPage로 5초 동안 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalyzingPage(
                      duration: const Duration(seconds: 5),
                      userName: widget.userName,
                      id: widget.id,
                      previousPageName: 'TranslatedPage',
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0))),
              child: const Text('분석 시작'),
            ),
            const SizedBox(height: 20),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.circle, color: Colors.red),
              iconSize: 80,
            ),
            const Text('양옆으로 바꿀 거임. 아니면 녹음 화면을 따로 만들던가?'),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('다시 녹음')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('정지')),
          ],
        ),
      ),
    );
  }
}
