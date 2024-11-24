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
    required this.inputText,
    required this.userVoicePath,
    required this.ttsVoicePath,
  });

  final String id;
  final String inputText;
  final String userVoicePath;
  final String ttsVoicePath;

  @override
  State<InputAnalyzingPage> createState() => InputAnalyzingState();
}

class InputAnalyzingState extends State<InputAnalyzingPage> {
  var region = '';
  var translatedText = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  //Map<String, String> headers = {
  //'Content-Type': 'multipart/form-data',
  //'Accept': 'application/gzip',
  //'Accept-Encoding': 'gzip',
  // };

  Future<void> _processRequest() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/voice-analysis'),
    );

    // Add files
    request.files.add(
        await http.MultipartFile.fromPath('tts_voice', widget.ttsVoicePath));
    request.files.add(
        await http.MultipartFile.fromPath('user_voice', widget.userVoicePath));

    // Add user ID as field
    request.fields['text'] = widget.inputText;
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        //뭘 넘겨줄 것인가
        final responseBody = await response.stream.bytesToString();
        final responseJson = jsonDecode(responseBody);

        //debugPrint(responseData.toString());
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/show"),
              builder: (context) => ShowPage(
                  id: widget.id,
                  text: widget.inputText,
                  ttsAudio: widget.ttsVoicePath,
                  userAudio: widget.userVoicePath,
                  result: responseJson['temp_id']),
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
