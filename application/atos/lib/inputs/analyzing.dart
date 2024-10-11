import 'package:atos/inputs/translated.dart';
import 'package:flutter/material.dart';
import 'package:atos/inputs/show.dart';
import 'package:atos/practice/tryresult.dart';

class AnalyzingPage extends StatefulWidget {
  const AnalyzingPage({
    super.key,
    required this.duration,
    required this.userName,
    required this.id,
    required this.previousPageName,
  });

  final Duration duration;
  final String userName;
  final String id;
  final String previousPageName;

  @override
  State<AnalyzingPage> createState() => AnalyzingState();
}

class AnalyzingState extends State<AnalyzingPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(widget.duration, () {
      if (mounted) {
        if (widget.previousPageName == 'TranslatedPage') {
          // 특정 페이지에서 왔을 경우 다른 처리
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/show"),
              builder: (context) =>
                  ShowPage(userName: widget.userName, id: widget.id),
            ),
          );
        } else if (widget.previousPageName == 'TryPage') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/tryresult"),
              builder: (context) =>
                  TryResultPage(userName: widget.userName, id: widget.id),
            ),
          );
        } else if (widget.previousPageName == 'AddPage') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/translated"),
              builder: (context) =>
                  TranslatedPage(userName: widget.userName, id: widget.id),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // 뒤로 가기 동작 비활성화
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('분석중이에요'),
              SizedBox(
                width: 100, // 원하는 너비
                height: 100, // 원하는 높이
                child: CircularProgressIndicator(
                  strokeWidth: 10, // 두께 조절
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
