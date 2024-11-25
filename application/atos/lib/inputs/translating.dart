//GPT를 사용해서 텍스트를 번역하고, TTS를 생성하는 동안 기다리는 페이지

import 'dart:convert';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:atos/inputs/translated.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TranslatingPage extends StatefulWidget {
  const TranslatingPage({
    super.key,
    required this.id,
    required this.inputText, // 번역할 텍스트
    required this.todo, // 번역 중인지 TTS 생성 중인지에 대한 메시지
    required this.theme, //테마
  });

  final String id;
  final String inputText;
  final String todo;
  final String theme;

  @override
  State<TranslatingPage> createState() => TranslatingState();
}

class TranslatingState extends State<TranslatingPage> {
  var region = ''; //지역
  var sex = ''; //성별
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchRegionAndProcessRequest();
  }

  Future<void> _fetchRegionAndProcessRequest() async {
    await _fetchRegionAndSex();
    await _processRequest();
  }

  //파이어스토어에서 지역과 성별을 가져옴
  Future<void> _fetchRegionAndSex() async {
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await db.collection('userData').doc(widget.id).get();
      setState(() {
        region = userDoc['region'] ?? ' ';
        sex = userDoc['sex'] ?? ' ';
      });
    }
  }

  //번역과 TTS생성 요청을 여기서 맡기기
  //add.dart에서 하려고 했는데, 번역이 끝나면 translating다음 페이지로 가는 방법을 모르겠어서
  //이 페이지로 인자를 받아와 여기서 처리하기로 함
  Future<void> _processRequest() async {
    //번역할 거면
    if (widget.todo == '번역중이에요..') {
      try {
        final response = await http.post(
          //translate-text가 번역하고 tts생성도 함
          Uri.parse('${ControlUri.BASE_URL}/translate-text'),
          body: json.encode({
            'text': widget.inputText,
            'user_id': widget.id,
            'region': region,
            'theme': widget.theme,
            'sex': sex,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          debugPrint(responseData.toString());
          if (mounted) {
            //번역 결과 페이지에 넘겨줄 인자
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: "/translated"),
                builder: (context) => TranslatedPage(
                  id: widget.id,
                  translatedText: responseData['translated_text_data'], //번역 결과
                  audioName:
                      responseData['audio_title'], // 생성된 TTS파일의 파이어베이스 안에서의 경로
                  translate: true, //번역한 건지
                ),
              ),
            );
          }
        } else {
          debugPrint("오류 발생: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("HTTP 요청 오류: $e");
      }
    } else {
      // 번역할 게 아니면
      try {
        final response = await http.post(
          //TTS파일만 바로 생성
          Uri.parse('${ControlUri.BASE_URL}/get-tts'),
          body: json.encode({
            'text': widget.inputText,
            'user_id': widget.id,
            'region': region,
            'theme': widget.theme,
            'sex': sex,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          debugPrint(responseData.toString());
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: "/translated"),
                builder: (context) => TranslatedPage(
                  id: widget.id,
                  translatedText: widget.inputText, // 번역 결과가 없으니 원문을 그대로
                  audioName: responseData['audio_title'],
                  translate: false, //번역 안함
                ),
              ),
            );
          }
        } else {
          debugPrint("오류 발생: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("HTTP 요청 오류: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // 뒤로 가기 동작 비활성화
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(widget.todo),
              SizedBox(height: 10),
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
