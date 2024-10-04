import 'package:flutter/material.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key, required this.userName, required this.id});

  final String userName;
  final String id;

  @override
  State<PracticePage> createState() => PracticeState();
}

class PracticeState extends State<PracticePage> {
  var inputText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('저장한 리스트?')),
          ],
        ),
      ),
    );
  }
}
