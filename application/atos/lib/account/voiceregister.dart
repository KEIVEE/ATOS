// 최고피치 최저피치 기록 페이지

import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  //권한 요청하고 녹음기 초기화
  Future<void> _initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
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
    final path = '${Directory.systemTemp.path}/pitch.wav';
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
      } else {
        _isRecordingHigh = false;
      }
    });
  }

  //음성 데이터 서버로 전송
  Future<void> _sendVoiceData() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/set-user-pitch'),
    );

    //멀티파트 전송
    request.files.add(await http.MultipartFile.fromPath('low', _lowPitchPath));
    request.files
        .add(await http.MultipartFile.fromPath('high', _highPitchPath));

    //ID도 같이 전송
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공. 로그인 해 주세요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 데이터 업로드 중 오류가 발생했습니다.')),
        );
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
        title: const Text('음성 등록'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 저음 입력 버튼
            ElevatedButton(
              onPressed: _isRecordingLow
                  ? () => _stopRecording('low')
                  : () => _startRecording('low'),
              child: Text(_isRecordingLow ? '녹음 끝내기' : '저음 입력하기'),
            ),
            // 고음 입력 버튼
            ElevatedButton(
              onPressed: _isRecordingHigh
                  ? () => _stopRecording('high')
                  : () => _startRecording('high'),
              child: Text(_isRecordingHigh ? '녹음 끝내기' : '고음 입력하기'),
            ),
            // 확인 버튼 (녹음된 파일을 서버로 전송)
            ElevatedButton(
              onPressed: (_lowPitchPath.isNotEmpty && _highPitchPath.isNotEmpty)
                  ? _sendVoiceData
                  : null,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
