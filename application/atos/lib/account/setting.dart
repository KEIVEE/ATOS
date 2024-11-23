import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:atos/control/uri.dart';

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

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _initializeNickname();
    _fetchRegion();
  }

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

  Future<void> _updateRegion(String newRegion) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final response = await http.post(
        Uri.parse('${ControlUri.BASE_URL}/set-user-region'), // 실제 서버 URL로 변경
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
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('지역 변경하기'),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButton(
                            value: region,
                            items: regions
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                region = value!;
                              });
                            },
                          );
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            _updateRegion(region);
                            Navigator.pop(context);
                          },
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('지역 변경하기'),
            ),
            //Text(region),
            // 닉네임 수정 버튼
            OutlinedButton(
              onPressed: () {
                // 닉네임 변경 입력을 위한 다이얼로그 표시
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('닉네임 수정'),
                      content: TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: '새 닉네임',
                        ),
                        onChanged: (text) {
                          newNickname = text; // 새로운 닉네임을 저장
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // 다이얼로그 닫기
                          },
                          child: Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            _updateNickname(); // 닉네임 업데이트
                            Navigator.pop(context); // 다이얼로그 닫기
                          },
                          child: Text('저장'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('닉네임 수정'),
            ),
          ],
        ),
      ),
    );
  }
}
