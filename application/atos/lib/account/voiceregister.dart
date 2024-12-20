// 최고피치 최저피치 기록 페이지

import 'dart:io';
import 'package:atos/control/ui.dart';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class VoiceRegisterPage extends StatefulWidget {
  final String id;
  const VoiceRegisterPage({super.key, required this.id});

  @override
  State<VoiceRegisterPage> createState() => _VoiceRegisterPageState();
}

class _VoiceRegisterPageState extends State<VoiceRegisterPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecordingLow = false;
  bool _isRecordingHigh = false;
  String _lowPitchPath = ''; // 저음 파일 경로
  String _highPitchPath = ''; // 고음 파일 경로

  bool lowDone = false;
  bool highDone = false;

  bool allDone = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  //권한 요청하고 녹음기 초기화
  Future<void> _initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      // 권한 거부 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      return;
    }
    await _recorder.openRecorder();
  }

  //녹음 시작
  Future<void> _startRecording(String pitch) async {
    var path = '';
    if (pitch == 'low') {
      path = '${Directory.systemTemp.path}/low.wav';
    } else {
      path = '${Directory.systemTemp.path}/high.wav';
    }
    await _recorder.startRecorder(toFile: path);
    setState(() {
      if (pitch == 'low') {
        _isRecordingLow = true;
        _lowPitchPath = path;
      } else {
        _isRecordingHigh = true;
        _highPitchPath = path;
      }
    });
  }

  //녹음 끝내기
  Future<void> _stopRecording(String pitch) async {
    await _recorder.stopRecorder();
    setState(() {
      if (pitch == 'low') {
        _isRecordingLow = false;
        lowDone = true;
        allDone = lowDone && highDone;
      } else {
        _isRecordingHigh = false;
        highDone = true;
        allDone = lowDone && highDone;
      }
    });
  }

  //음성 데이터 서버로 전송
  Future<void> _sendVoiceData() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/set-user-pitch'),
    );

    request.headers['Authorization'] = 'Bearer ${ControlUri.TOKEN}';

    //멀티파트 전송
    request.files.add(await http.MultipartFile.fromPath('low', _lowPitchPath));
    request.files
        .add(await http.MultipartFile.fromPath('high', _highPitchPath));

    //ID도 같이 전송
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공. 로그인 해 주세요.')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('음성 데이터 업로드 중 오류가 발생했습니다.')),
          );
          debugPrint('오류 발생: ${response.toString()}');
        }
      }

      //가입이 끝났으니 초기화면 = main.dart로 이동
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음성 데이터 등록하기'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // 저음 입력 버튼
            SizedBox(height: 50),
            CustomedButton(
              text: _isRecordingLow ? '녹음 끝내기' : '저음 입력하기',
              buttonColor: Theme.of(context).primaryColor,
              textColor: Colors.white,
              onTap: _isRecordingLow
                  ? () => _stopRecording('low')
                  : () => _startRecording('low'),
            ),
            //const Text('현재 저음 고음값 가져올 수 있나?'),
            const SizedBox(height: 20),
            // 고음 입력 버튼
            CustomedButton(
              text: _isRecordingHigh ? '녹음 끝내기' : '고음 입력하기',
              buttonColor: Theme.of(context).primaryColor,
              textColor: Colors.white,
              onTap: _isRecordingHigh
                  ? () => _stopRecording('high')
                  : () => _startRecording('high'),
            ),

            const SizedBox(height: 50),
            // 확인 버튼 (녹음된 파일을 서버로 전송)
            CustomedButton(
              text: '확인',
              buttonColor:
                  allDone ? Theme.of(context).primaryColor : Colors.grey,
              textColor: Colors.white,
              onTap: allDone ? _sendVoiceData : null,
            ),
          ],
        ),
      ),
    );
  }
}
