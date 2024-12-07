//번역 결과를 보여주고 음성 녹음까지 하는 페이지

import 'package:atos/control/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'inputanalyzing.dart';

// TranslatedPage는 음성 녹음 및 업로드와 관련된 기능을 포함하는 StatefulWidget
class TranslatedPage extends StatefulWidget {
  const TranslatedPage(
      {super.key,
      required this.id,
      required this.translatedText,
      required this.audioName,
      required this.translate});
  final String id;
  final String translatedText; // 번역된 텍스트
  final String audioName; // TTS 파일 경로
  final bool translate; // 번역 여부

  @override
  State<TranslatedPage> createState() => _TranslatedState();
}

class _TranslatedState extends State<TranslatedPage> {
  final recorder =
      sound.FlutterSoundRecorder(); // FlutterSoundRecorder 객체로 음성 녹음 기능 제공
  bool isRecording = false; // 녹음 중인지 여부를 저장하는 변수
  String recordedFilePath = ""; // 녹음된 파일 경로 저장
  String standardFilePath = ""; // TTS 파일 경로 저장
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool done = false;

  String downloadURL = '';

  Future<void> _playAudio() async {
    try {
      // 오디오 플레이어를 통해 TTS음성 파일 재생
      await _audioPlayer.play(UrlSource(downloadURL));
    } catch (e) {
      debugPrint("오디오 재생 오류: $e");
    }
  }

  Future<void> setTTSDownloadUrl() async {
    try {
      // Firebase Storage에서 파일의 다운로드 URL 가져오기
      String url =
          await _storage.ref().child(widget.audioName).getDownloadURL();
      setState(() {
        downloadURL = url;
      });
      debugPrint("다운로드 URL 설정 성공: $downloadURL");
    } catch (e) {
      debugPrint("다운로드 링크 오류: $e");
    }
  }

  //파일 다운로드 하기. 앱 내부 스토리지에 함
  Future<void> downloadAndSaveTTSFile() async {
    try {
      // 다운로드할 파일의 경로 설정
      final directory = await getApplicationDocumentsDirectory();
      standardFilePath = '${directory.path}/${widget.audioName}';

      // 파일 다운로드
      final response = await Dio().download(downloadURL, standardFilePath);

      if (response.statusCode == 200) {
        debugPrint("파일 다운로드 성공: $standardFilePath");
      } else {
        debugPrint("파일 다운로드 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("파일 다운로드 오류: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    recorder.closeRecorder(); // 녹음기를 닫음
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeRecorder(); // 초기화 시 녹음기 초기화
    _initializeDownload();
  }

  Future<void> _initializeDownload() async {
    await setTTSDownloadUrl();
    await downloadAndSaveTTSFile();
  }

  // 마이크 권한을 요청하고 녹음기를 초기화하는 메소드
  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request(); // 마이크 권한 요청
    if (status != PermissionStatus.granted) {
      if (mounted) {
        // 위젯이 여전히 화면에 있으면
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
      }
      return;
    }
    await recorder.openRecorder(); // 녹음기 열기
  }

  // 녹음을 시작하는 메소드
  Future<void> startRecording() async {
    final directory =
        await getApplicationDocumentsDirectory(); // 앱의 문서 디렉터리 가져오기
    final path = p.join(directory.path, 'recorded_audio.wav'); // 녹음 파일 경로 설정
    await recorder.startRecorder(toFile: path); // 녹음 시작
    if (mounted) {
      // 위젯이 여전히 화면에 있으면
      setState(() {
        isRecording = true; // 녹음 상태 변경
        recordedFilePath = path; // 파일 경로 저장
      });
    }
  }

  // 녹음을 중지하고 업로드하는 메소드
  Future<void> stopRecording() async {
    await recorder.stopRecorder(); // 녹음 중지
    if (mounted) {
      // 위젯이 여전히 화면에 있으면
      setState(() {
        isRecording = false; // 녹음 상태 변경
        done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 버튼
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),

            if (widget.translate)
              const Text(
                '번역된 문장이에요',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            const SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0), // 원하는 패딩 값 설정
              child: Text(
                widget.translatedText,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            // 분석 시작 버튼

            ManageSizedBox(
                content: SingleChildScrollView(
                    child: Column(
                  children: [
                    SizedBox(height: 50),

                    // 녹음 버튼
                    IconButton(
                      onPressed: isRecording ? stopRecording : startRecording,
                      icon: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        color: isRecording ? Colors.red : Colors.blue,
                      ),
                      iconSize: 80,
                    ),
                    const SizedBox(height: 20),

                    CustomedButton(
                      text: '표준어 듣기',
                      buttonColor: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      onTap: () async {
                        await _playAudio();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomedButton(
                      text: '분석 시작',
                      buttonColor:
                          done ? Theme.of(context).primaryColor : Colors.grey,
                      textColor: Colors.white,
                      onTap: done
                          ? () async {
                              Navigator.of(context).push(MaterialPageRoute(
                                  //translating.dart처럼 실제로 post요청은 inputanalyzing.dart에서 함
                                  settings: const RouteSettings(
                                      name: "/inputanalyzing"),
                                  builder: (context) => InputAnalyzingPage(
                                      id: widget.id, //요청을 하기 위한 인자들은
                                      inputText: widget.translatedText, //텍스트
                                      userVoicePath:
                                          recordedFilePath, //녹음 파일 경로
                                      ttsVoicePath:
                                          standardFilePath))); // TTS 파일 경로
                            }
                          : null,
                    ),
                  ],
                )),
                boxHeight: 700)
          ],
        ),
      ),
    );
  }
}
