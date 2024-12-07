//연습 하나마다 버튼을 만들어주는 클래스

import 'package:atos/practice/content.dart';
import 'package:flutter/material.dart';

class TitleButton extends StatelessWidget {
  final String title;
  final String sentence;
  final String id;
  final String date;

  const TitleButton({
    super.key,
    required this.title, //제목
    required this.id, //유저 아이디
    required this.sentence, //문장
    required this.date,
  }); //파일 저장 경로

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10), // 원하는 여백 설정
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: RouteSettings(name: "/content"),
                builder: (context) => ContentPage(
                  id: id,
                  title: title,
                  sentence: sentence,
                ),
              ),
            );
          },
          child: Card(
            elevation: 5,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: [
                      SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Text(date,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
