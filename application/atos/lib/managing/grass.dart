import 'package:flutter/material.dart';

class GrassBox extends StatelessWidget {
  final String date;
  final int visited;

  const GrassBox({super.key, required this.date, required this.visited});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4), // 원하는 패딩 값 설정
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: visited > 0 ? Color.fromRGBO(42, 52, 110, 1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 5),
            Text(
              date,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
