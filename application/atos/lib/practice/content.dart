import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:atos/practice/try.dart';
//import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    super.key,
    required this.id,
    required this.title,
    required this.sentence,
    required this.path,
  });
  final String id;
  final String title;
  final String sentence;
  final String path;

  @override
  State<ContentPage> createState() => ContentState();
}

class ContentState extends State<ContentPage> {
  String resultFilePath = "";
  String recordedFilePath = ""; // 녹음된 파일 경로 저장
  String standardFilePath = ""; // TTS 파일 경로 저장

  String resultDownloadURL = '';
  String ttsDownloadURL = '';
  String userDownloadURL = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String jsonData = '';

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    fetchResultAndAudios();
    super.initState();
  }

  Future<void> fetchResultAndAudios() async {
    await setDownloadUrl();
    await downloadAndSave();
    await readJsonData();
  }

  Future<void> setDownloadUrl() async {
    try {
      // Firebase Storage에서 파일의 다운로드 URL 가져오기
      String resultUrl = await _storage
          .ref()
          .child(widget.path)
          .child('analysis.json')
          .getDownloadURL();
      String ttsUrl = await _storage
          .ref()
          .child(widget.path)
          .child('ttsVoice.wav')
          .getDownloadURL();
      String userUrl = await _storage
          .ref()
          .child(widget.path)
          .child('userVoice.wav')
          .getDownloadURL();
      setState(() {
        resultDownloadURL = resultUrl;
        ttsDownloadURL = ttsUrl;
        userDownloadURL = userUrl;
      });
      debugPrint("다운로드 URL 설정 성공: $resultDownloadURL");
      debugPrint("다운로드 URL 설정 성공: $ttsDownloadURL");
      debugPrint("다운로드 URL 설정 성공: $userDownloadURL");
    } catch (e) {
      debugPrint("다운로드 링크 오류: $e");
    }
  }

  Future<void> downloadAndSave() async {
    try {
      // 다운로드할 파일의 경로 설정
      final directory = await getApplicationDocumentsDirectory();
      resultFilePath = '${directory.path}/analysis.json';
      standardFilePath = '${directory.path}/ttsVoice.wav';
      recordedFilePath = '${directory.path}/userVoice.wav';

      // 파일 다운로드
      final resultResponse =
          await Dio().download(resultDownloadURL, resultFilePath);
      final ttsResponse =
          await Dio().download(ttsDownloadURL, standardFilePath);
      final userResponse =
          await Dio().download(userDownloadURL, recordedFilePath);

      if (resultResponse.statusCode == 200) {
        debugPrint("파일 다운로드 성공: $resultFilePath");
      } else {
        debugPrint("파일 다운로드 실패: ${resultResponse.statusCode}");
      }
      if (ttsResponse.statusCode == 200) {
        debugPrint("파일 다운로드 성공: $standardFilePath");
      } else {
        debugPrint("파일 다운로드 실패: ${ttsResponse.statusCode}");
      }
      if (userResponse.statusCode == 200) {
        debugPrint("파일 다운로드 성공: $recordedFilePath");
      } else {
        debugPrint("파일 다운로드 실패: ${userResponse.statusCode}");
      }
    } catch (e) {
      debugPrint("파일 다운로드 오류: $e");
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      // 오디오 플레이어를 통해 음성 파일 재생
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint("오디오 재생 오류: $e");
    }
  }

  Future<void> readJsonData() async {
    try {
      final file = File(resultFilePath); // 저장된 JSON 파일 경로
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          jsonData = contents;
        });
        debugPrint('JSON 데이터 읽기 성공.');
      } else {
        debugPrint('JSON 파일이 존재하지 않습니다.');
      }
    } catch (e) {
      debugPrint('JSON 데이터 읽기 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(widget.title),
            Text(widget.sentence),
            const Text('문명 그래프'),
            Text(widget.path),
            OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/try"),
                      builder: (context) => TryPage(id: widget.id),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('연습하기')),
            OutlinedButton(
                onPressed: () {
                  _playAudio(standardFilePath);
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('표준어 들어보기')),
            OutlinedButton(
                onPressed: () {
                  _playAudio(recordedFilePath);
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('내 발음 들어보기')),
          ],
        ),
      ),
    );
  }
}
