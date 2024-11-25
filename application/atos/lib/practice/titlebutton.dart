//연습 하나마다 버튼을 만들어주는 클래스

import 'package:atos/practice/content.dart';
import 'package:flutter/material.dart';

class TitleButton extends StatelessWidget {
  final String title;
  final String sentence;
  final String id;
  final String path;

  const TitleButton(
      {super.key,
      required this.title, //제목
      required this.id, //유저 아이디
      required this.sentence, //문장
      required this.path}); //파일 저장 경로

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(name: "/content"),
            builder: (context) => ContentPage(
              id: id,
              title: title,
              sentence: sentence,
              path: path,
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding:
            EdgeInsets.symmetric(horizontal: 20, vertical: 20), // 버튼의 패딩 조정
        textStyle: TextStyle(fontSize: 24), // 텍스트 스타일 조정
        minimumSize: Size(220, 80), // 버튼의 최소 크기 조정
        side: BorderSide(color: Colors.indigo, width: 2), // 테두리 색상과 두께 조정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // 모서리를 더 각지게 조정
        ),
      ),
      child: Text(
        title,
        style: TextStyle(color: Colors.indigo), // 텍스트 색상 조정
      ),
    );
  }
}
