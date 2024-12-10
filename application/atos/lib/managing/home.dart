//오늘의 문장, 잔디심기(깃허브에 있는거처럼), 설정 버튼을 가진 화면
//login.dart에서 로그인 기록을 저장하는 이유가 잔디심기임

import 'dart:convert';

import 'package:atos/control/ui.dart';
import 'package:atos/control/uri.dart';
import 'package:atos/inputs/translating.dart';
import 'package:atos/managing/grass.dart';
import 'package:atos/practice/titlebutton.dart';
import 'package:flutter/material.dart';
import 'package:atos/account/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.id});
  final String id;

  @override
  State<HomePage> createState() => HomeState();
}

class HomeState extends State<HomePage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  var connectTried = false;
  var reccomendation = '';
  var date = List<String>.filled(7, '-');
  var visited = List<int>.filled(7, 0);
  var times = '';
  var first = true;

  var recentTitle = '';
  var recentSentence = '';
  var recentDate = '';

  bool isLoading = true; // 로딩 상태 플래그

  @override
  void initState() {
    super.initState();
    getReccomendationAndGrass();
  }

  Future<void> getReccomendationAndGrass() async {
    try {
      await getReccomendation();
      await getGrass();
      await getRecent();
    } finally {
      setState(() {
        isLoading = false; // 데이터 로드 완료
      });
    }
  }

  Future<void> getReccomendation() async {
    http.Response response = await http.post(
        Uri.parse('${ControlUri.BASE_URL}/get-today-sentence'),
        headers: ControlUri.headerUtf8);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedBody);
      final String sentence = data['data']['sentence'];
      setState(() {
        reccomendation = sentence;
      });
    } else {
      setState(() {
        reccomendation = '오늘의 추천 문장을 가져오는데 실패했어요.';
      });
    }
  }

  Future<void> getGrass() async {
    http.Response response = await http.get(
      Uri.parse(
        '${ControlUri.BASE_URL}/get-green-graph/${widget.id}',
      ),
      headers: ControlUri.headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        date = List<String>.from(data['data']['week_dates']);
        visited = List<int>.from(data['data']['green_graph']);
        times = data['data']['num'];
      });
    }
  }

  Future<void> getRecent() async {
    http.Response response = await http.get(
        Uri.parse(
            '${ControlUri.BASE_URL}/get-user-practice-recent/${widget.id}'),
        headers: ControlUri.headerUtf8);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedBody);
      setState(() {
        recentTitle = data['title'];
        recentSentence = data['text'];
        recentDate = data['date'];
        first = false;
      });
    } else if (response.statusCode == 404) {
      setState(() {
        first = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // 로딩 화면 표시
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // 데이터 로드 후 실제 화면 표시
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // 설정 버튼
              SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: "/settiing"),
                            builder: (context) => SettingPage(id: widget.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 추천 문장
              const Text('오늘의 문장', style: TextStyle(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  reccomendation,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 10),
              // 시도하기 버튼
              CustomedButton(
                text: '시도하기',
                buttonColor: Colors.white,
                textColor: Theme.of(context).primaryColor,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: "/processing"),
                    builder: (context) => TranslatingPage(
                      id: widget.id,
                      inputText: reccomendation,
                      todo: "처리중이에요..",
                      theme: "차분한",
                    ),
                  ));
                },
              ),
              const SizedBox(height: 20),
              // 잔디심기
              ManageSizedBox(
                content: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 20),
                        Text('일주일 동안 $times번 방문했어요.',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 7; i++)
                          GrassBox(date: date[i], visited: visited[i]),
                      ],
                    ),
                    const Text('최근 활동',
                        style: TextStyle(fontSize: 30, height: 3)),
                    if (!first)
                      TitleButton(
                        title: recentTitle,
                        sentence: recentSentence,
                        id: widget.id,
                        date: recentDate,
                      ),
                    if (first)
                      const Text('최근 활동이 없어요.',
                          style: TextStyle(fontSize: 20, height: 3)),
                  ],
                ),
                boxHeight: 547,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
