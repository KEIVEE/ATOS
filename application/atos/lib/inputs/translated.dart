import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지
import 'dart:io'; // File 객체 사용
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
//import 'package:atos/inputs/inputanalyzing.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';

// TranslatedPage는 음성 녹음 및 업로드와 관련된 기능을 포함하는 StatefulWidget
class TranslatedPage extends StatefulWidget {
  const TranslatedPage(
      {super.key,
      required this.id,
      required this.translatedText,
      required this.audioName});
  final String id;
  final String translatedText;
  final String audioName;

  @override
  State<TranslatedPage> createState() => _TranslatedState();
}

class _TranslatedState extends State<TranslatedPage> {
  final recorder =
      sound.FlutterSoundRecorder(); // FlutterSoundRecorder 객체로 음성 녹음 기능 제공
  bool isRecording = false; // 녹음 중인지 여부를 저장하는 변수
  String? recordedFilePath; // 녹음된 파일 경로 저장
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playAudio() async {
    try {
      // Firebase Storage에서 파일의 다운로드 URL 가져오기
      String downloadURL =
          await _storage.ref().child(widget.audioName).getDownloadURL();

      //print(downloadURL);

      // 오디오 플레이어를 통해 음성 파일 재생
      await _audioPlayer.play(UrlSource(downloadURL));
    } catch (e) {
      debugPrint("오디오 재생 오류: $e");
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
    final path = p.join(directory.path, 'recorded_audio.aac'); // 녹음 파일 경로 설정
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
      });
    }
    if (recordedFilePath != null) {
      // 녹음이 완료되면 파일 업로드
      await uploadAudioFile(File(recordedFilePath!));
    }
  }

  // 서버에 음성 파일을 업로드하는 메소드
  Future<void> uploadAudioFile(File audioFile) async {
    const String apiUrl = 'http://222.237.88.211:8000/'; // 서버 API URL
    try {
      // 현재 시각을 가져옵니다.
      String currentTime = DateTime.now().toIso8601String();

      // HTTP 요청을 생성
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file', // 서버에서 받을 필드 이름
        audioFile.path, // 파일 경로
      ));
      request.fields['id'] = widget.id; // 사용자 ID 필드 추가
      request.fields['time'] = currentTime; // 현재 시각 필드 추가

      // 요청을 전송하고 응답을 받음
      var response = await request.send();
      if (mounted) {
        // 위젯이 여전히 화면에 있으면
        if (response.statusCode == 200) {
          // 업로드 성공 시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('음성 파일 업로드 성공!')),
          );
        } else {
          // 업로드 실패 시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업로드 실패: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // 업로드 중 오류가 발생한 경우
      if (mounted) {
        // 위젯이 여전히 화면에 있으면
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 중 오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 버튼
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              '변환된 문장이에요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.translatedText,
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            // 분석 시작 버튼
            OutlinedButton(
              onPressed: null,
              /*() {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InputAnalyzingPage(
                      duration: const Duration(seconds: 3),
                      userName: widget.userName,
                      id: widget.id,
                      previousPageName: 'TranslatedPage',
                    ),
                  ),
                );
              },*/
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('분석 시작'),
            ),
            const SizedBox(height: 20),
            // 녹음 버튼
            IconButton(
              onPressed: isRecording ? stopRecording : startRecording,
              icon: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: isRecording ? Colors.red : Colors.blue,
              ),
              iconSize: 80,
            ),
            const Text('양옆으로 바꿀 거임. 아니면 녹음 화면을 따로 만들던가?'),
            Text(widget.audioName),
            // 다시 녹음 버튼
            OutlinedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('다시 녹음'),
            ),
            // 정지 버튼
            OutlinedButton(
              onPressed: stopRecording,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('정지'),
            ),

            OutlinedButton(
              onPressed: _playAudio,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('표준어 듣기'),
            ),
          ],
        ),
      ),
    );
  }
}
