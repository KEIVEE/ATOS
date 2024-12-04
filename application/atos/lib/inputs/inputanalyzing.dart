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

  Future<void> _processRequest() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/voice-analysis'),
    );

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
    }
  }

  Future<void> _fetchFileAndProcessRequest() async {
    await _processRequest();
  }

  @override
  void initState() {
    super.initState();
    _fetchFileAndProcessRequest();
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
