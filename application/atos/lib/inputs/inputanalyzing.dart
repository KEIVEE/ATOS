import 'dart:math';

import 'package:atos/inputs/show.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atos/control/uri.dart';

class InputAnalyzingPage extends StatefulWidget {
  const InputAnalyzingPage({
    super.key,
    required this.id,
    required this.inputText, // 텍스트
    required this.userVoicePath, // 사용자 음성 파일 경로. 앱 내부 경로임
    required this.ttsVoicePath, // TTS 음성 파일 경로. 앱 내부 경로임
    this.title,
  });

  final String id;
  final String inputText;
  final String userVoicePath;
  final String ttsVoicePath;
  final String? title;

  @override
  State<InputAnalyzingPage> createState() => InputAnalyzingState();
}

class InputAnalyzingState extends State<InputAnalyzingPage> {
  var region = '';
  var translatedText = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  var youKnowWhat = '';

  Future<void> _processRequest() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/voice-analysis'),
    );

    request.headers['Authorization'] = 'Bearer ${ControlUri.TOKEN}';

    // 멀티파트 요청에 필요한 파일
    request.files.add(
        await http.MultipartFile.fromPath('tts_voice', widget.ttsVoicePath));
    request.files.add(
        await http.MultipartFile.fromPath('user_voice', widget.userVoicePath));

    // 나머지 필요한 필드들
    request.fields['text'] = widget.inputText;
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        //show.dart에 뭘 넘겨줄 것인가
        final responseBody = await response.stream.bytesToString();
        final responseJson = jsonDecode(responseBody);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/show"),
              builder: (context) => ShowPage(
                id: widget.id,
                text: widget.inputText, //텍스트
                ttsAudio: widget.ttsVoicePath, //TTS 음성 파일 경로
                userAudio: widget.userVoicePath, //사용자 음성 파일 경로
                result: responseJson['temp_id'],
                title: widget.title,
              ), //결과가 저장된 파이어베이스 경로
            ),
          );
        }
      } else {
        debugPrint("오류 발생: ${response.statusCode}");
        debugPrint("오류 발생: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("HTTP 요청 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('음성을 제대로 인식하지 못했어요.')));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _fetchFileAndProcessRequest() async {
    await _processRequest();
  }

  @override
  void initState() {
    int youKnowWhatNumber = Random().nextInt(3);
    if (youKnowWhatNumber == 0) {
      youKnowWhat =
          '방언은 오방지언이라는 단어에서 유래되었어요. \n여기서 오방은 동방, 서방, 남방, 북방, 중방을 합친 말로, \n오방지언은 “각 지방의 말” 이라는 뜻이에요.';
    } else if (youKnowWhatNumber == 1) {
      youKnowWhat = '“저번주”는 강원도, 충청남도의 사투리로 \n“지난주”가 표준어입니다.';
    } else if (youKnowWhatNumber == 2) {
      youKnowWhat =
          '데덴찌(서울), 젠~디(부산), \n뺀다뺀다 또뺀다(대구), \n편뽑기 편뽑기 알코르세요(광주)는 \n모두 손바닥으로 편을 가르는 말입니다.';
    }
    _fetchFileAndProcessRequest();
    super.initState();
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
              Text('분석중이에요'),
              SizedBox(height: 10),
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 10,
                ),
              ),
              SizedBox(height: 10),
              Text('그거 아시나요?',
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold)),
              Text(
                youKnowWhat,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
