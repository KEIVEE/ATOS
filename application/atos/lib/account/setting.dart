import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:atos/control/uri.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.id});
  final String id;

  @override
  State<SettingPage> createState() => SettingState();
}

class SettingState extends State<SettingPage> {
  String newNickname = ""; // 새 닉네임을 저장할 변수
  late TextEditingController _nicknameController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final List<String> regions = ['경상도', '전라도', '충청도', '강원도', '제주도'];

  String region = "";

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecordingLow = false;
  bool _isRecordingHigh = false;
  String _lowPitchPath = '';
  String _highPitchPath = '';
  bool lowTried = false; // 저음 녹음 시도 여부
  bool highTried = false; // 고음 녹음 시도 여부
  bool nicknameVacant = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _initializeNickname();
    _fetchRegion();
    _initRecorder();
  }

  // 지역 가지고 오기. api로 받아와도 되는데 아직 변경하지 않음
  Future<void> _fetchRegion() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await db.collection('userData').doc(widget.id).get();
      setState(() {
        region = userDoc['region'] ?? ' ';
      });
    }
  }

  //지역 업데이트하기
  Future<void> _updateRegion(String newRegion) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final response = await http.post(
        Uri.parse('${ControlUri.BASE_URL}/set-user-region'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.id,
          'region': newRegion,
        }),
      );

      debugPrint(response.body);

      if (response.statusCode == 200) {
        setState(() {
          region = newRegion;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지역이 성공적으로 변경되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지역 변경에 실패했습니다.')),
        );
      }
    }
  }

  //닉네임 변경 텍스트필드 기본값 설정하기
  Future<void> _initializeNickname() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _nicknameController.text = user.displayName ?? '';
      });
    }
  }

  // 닉네임을 Firebase에서 업데이트하는 함수
  Future<void> _updateNickname() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newNickname);
      setState(() {
        _nicknameController.text = newNickname;
        nicknameVacant = true;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('닉네임이 변경되었습니다.')),
    );
  }

  //녹음기 권한 받아와서 시작하기
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

  // 저음 녹음 시작
  Future<void> _startRecordingLow() async {
    final path = '${Directory.systemTemp.path}/new_low_pitch.wav';
    setState(() {
      _isRecordingLow = true;
      _lowPitchPath = path;
    });
    await _recorder.startRecorder(toFile: path);
  }

  // 고음 녹음 시작
  Future<void> _startRecordingHigh() async {
    final path = '${Directory.systemTemp.path}/new_high_pitch.wav';
    setState(() {
      _isRecordingHigh = true;
      _highPitchPath = path;
    });
    await _recorder.startRecorder(toFile: path);
  }

  // 녹음 중지
  Future<void> _stopLowRecording() async {
    setState(() {
      _isRecordingLow = false;
      lowTried = true;
    });
    await _recorder.stopRecorder();
  }

  // 녹음 중지
  Future<void> _stopHighRecording() async {
    setState(() {
      _isRecordingHigh = false;
      highTried = true; //시도를 해야 저장 버튼을 누를 수 있게 함. 초기값은 false
    });
    await _recorder.stopRecorder();
  }

  // 저음 데이터 서버로 전송
  Future<void> sendLowPitchVoiceData() async {
    if (_lowPitchPath.isEmpty) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/set-user-low-pitch'), // 저음 전송 URL
    );

    request.files.add(await http.MultipartFile.fromPath('low', _lowPitchPath));
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('Low pitch voice data uploaded successfully');
      } else {
        print('Error uploading low pitch voice data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 고음 데이터 서버로 전송
  Future<void> sendHighPitchVoiceData() async {
    if (_highPitchPath.isEmpty) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ControlUri.BASE_URL}/set-user-high-pitch'), // 고음 전송 URL
    );

    request.files
        .add(await http.MultipartFile.fromPath('high', _highPitchPath));
    request.fields['user_id'] = widget.id;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('High pitch voice data uploaded successfully');
      } else {
        print('Error uploading high pitch voice data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 저음 변경 팝업
  Future<void> _showLowPitchDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('저음 변경하기'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _isRecordingLow
                        ? () {
                            _stopLowRecording();
                          }
                        : () {
                            _startRecordingLow();
                          },
                    child: Text(_isRecordingLow ? '녹음 그만하기' : '녹음하기'),
                  ),
                  ElevatedButton(
                    onPressed: !lowTried // 녹음이 중지되면 저장 버튼 활성화
                        ? null
                        : () {
                            sendLowPitchVoiceData(); // 서버로 전송
                            Navigator.pop(context);
                          },
                    child: Text('저장'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('취소'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // 고음 변경 팝업
  Future<void> _showHighPitchDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('고음 변경하기'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _isRecordingHigh
                        ? () {
                            _stopHighRecording();
                            setState(() {}); // 녹음 중지 후 상태 업데이트
                          }
                        : () {
                            _startRecordingHigh();
                            setState(() {}); // 녹음 시작 후 상태 업데이트
                          },
                    child: Text(_isRecordingHigh ? '녹음 그만하기' : '녹음하기'),
                  ),
                  ElevatedButton(
                    onPressed: !highTried // 녹음이 중지되면 저장 버튼 활성화
                        ? null
                        : () {
                            sendHighPitchVoiceData(); // 서버로 전송
                            Navigator.pop(context);
                          },
                    child: Text('저장'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('취소'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('설정'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: '닉네임',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              setState(() {
                newNickname = text;
                nicknameVacant = false;
                if (text == "") {
                  nicknameVacant = true;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: nicknameVacant ? null : _updateNickname,
            child: Text('닉네임 변경'),
          ),
          const SizedBox(height: 16),
          Text('현재 지역: $region'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 지역 변경 다이얼로그
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('지역 변경'),
                    content: DropdownButton<String>(
                      value: region,
                      onChanged: (newRegion) {
                        if (newRegion != null) {
                          _updateRegion(newRegion);
                          Navigator.pop(context);
                        }
                      },
                      items: regions
                          .map((region) => DropdownMenuItem<String>(
                                value: region,
                                child: Text(region),
                              ))
                          .toList(),
                    ),
                  );
                },
              );
            },
            child: Text('지역 변경'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showLowPitchDialog,
            child: Text('저음 변경하기'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showHighPitchDialog,
            child: Text('고음 변경하기'),
          ),
        ],
      ),
    );
  }
}
