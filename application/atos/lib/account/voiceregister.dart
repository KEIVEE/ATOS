import 'dart:convert';
import 'dart:io';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';

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
  String _lowPitchPath = '';
  String _highPitchPath = '';

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _startRecordingLow() async {
    final path = 'path_to_save_low_pitch.wav';
    await _recorder.startRecorder(toFile: path);
    setState(() {
      _isRecordingLow = true;
      _lowPitchPath = path;
    });
  }

  Future<void> _startRecordingHigh() async {
    final path = 'path_to_save_high_pitch.wav';
    await _recorder.startRecorder(toFile: path);
    setState(() {
      _isRecordingHigh = true;
      _highPitchPath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecordingLow = false;
      _isRecordingHigh = false;
    });
  }

  Future<void> _sendVoiceData() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/set-user-pitch'), // 서버 API URL
    );

    // Add files
    request.files.add(await http.MultipartFile.fromPath('low', _lowPitchPath));
    request.files.add(await http.MultipartFile.fromPath('high', _highPitchPath));

    // Add user ID as field
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        // 성공적으로 음성 파일 전송
        print('Voice data uploaded successfully');
        // 서버 응답에 따라 추가 동작 처리 가능
      } else {
        print('Error uploading voice data');
      }
    } catch (e) {
      print('Error: $e');
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 저음 입력하기 버튼
            ElevatedButton(
              onPressed: _isRecordingLow ? null : _startRecordingLow,
              child: Text(_isRecordingLow ? '녹음 중...' : '저음 입력하기'),
            ),
            // 고음 입력하기 버튼
            ElevatedButton(
              onPressed: _isRecordingHigh ? null : _startRecordingHigh,
              child: Text(_isRecordingHigh ? '녹음 중...' : '고음 입력하기'),
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
