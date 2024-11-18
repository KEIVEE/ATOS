import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.userName, required this.id});
  final String userName; // userName을 SettingPage 클래스에서 받아옵니다.
  final String id;

  @override
  State<SettingPage> createState() => SettingState();
}

class SettingState extends State<SettingPage> {
  String newNickname = ""; // 새 닉네임을 저장할 변수
  late String userName; // userName을 State에서 관리합니다.

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    userName = widget.userName; // widget.userName을 가져와서 userName에 할당
  }

  // 닉네임을 Firebase에서 업데이트하는 함수
  Future<void> updateNickname() async {
    if (newNickname.isEmpty) {
      return; // 닉네임이 비어 있으면 업데이트하지 않음
    }
    try {
      // Firebase에서 사용자의 displayName 업데이트
      await _auth.currentUser?.updateDisplayName(newNickname);

      // 성공적으로 업데이트되면 알림 메시지 표시
      if (mounted) { // mounted가 true일 때만 ScaffoldMessenger 사용
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임이 성공적으로 변경되었습니다.')),
        );
      }

      // 성공적으로 업데이트되면 새로운 닉네임을 화면에 반영
      if (mounted) { // mounted가 true일 때만 setState 호출
        setState(() {
          userName = newNickname; // UI에 표시된 userName 갱신
        });
      }

      // 다이얼로그를 닫을 때도 mounted 체크
      if (mounted) {
        Navigator.pop(context); // 다이얼로그 닫기
      }
    } catch (e) {
      // 오류가 발생하면 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임 변경 중 오류가 발생했습니다: ${e.toString()}')),
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
                        decoration: InputDecoration(
                          labelText: '새 닉네임',
                        ),
                        onChanged: (text) {
                          setState(() {
                            newNickname = text; // 새로운 닉네임을 저장
                          });
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            if (mounted) {
                              Navigator.pop(context); // 다이얼로그 닫기
                            }
                          },
                          child: Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            updateNickname(); // 닉네임 업데이트
                            // 다이얼로그 닫기는 updateNickname에서 처리됨
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
              child: const Text('닉네임 수정'),
            ),
            // 변경된 닉네임 표시
            Text('현재 닉네임: $userName'),
          ],
        ),
      ),
    );
  }
}
