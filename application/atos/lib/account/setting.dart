import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    // 초기 닉네임 설정
    _nicknameController = TextEditingController();
    _initializeNickname();
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
            // 지역 변경 버튼 (여기선 팝업으로 하겠다고 언급)
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('지역 변경하기: 팝업으로 할 거임.'),
            ),
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
