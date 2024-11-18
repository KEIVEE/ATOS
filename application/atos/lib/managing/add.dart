import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:atos/inputs/analyzing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.userName, required this.id});

  final String userName;
  final String id;

  @override
  State<AddPage> createState() => AddState();
}

class AddState extends State<AddPage> {
  var inputText = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 5),
            TextField(
              maxLines: 20,
              decoration: const InputDecoration(
                  labelText: '텍스트를 입력해주세요.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 250.0,
                    maxWidth: 350.0,
                  )),
              onChanged: (text) {
                inputText = text;
              },
            ),
            const Text('바로 연습할건지, 아니면 번역을 거칠 건지'),
            OutlinedButton(
                onPressed: () async {
                  if (inputText.isEmpty) {
                    // 입력 텍스트가 비어있을 경우
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('텍스트를 입력해주세요.')),
                    );
                    return;
                  }

                  try {
                    http.Response response = await http.post(
                        Uri.parse('http://localhost:8000/set_user'),
                        body:
                            json.encode({'user_id': widget.id, 'sex': "male"}),
                        headers: headers);

                    if (response.statusCode != 200) {
                      debugPrint("회원가입 오류.");
                    }

                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: "/analyzing"),
                          builder: (context) => AnalyzingPage(
                            duration: const Duration(seconds: 3),
                            userName: widget.userName,
                            id: widget.id,
                            previousPageName: 'AddPage',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // 예외 처리
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류 발생: ${e.toString()}')),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('확인')),
            const Text('양옆으로 바꿀 거임\n그리고 테마선택'),
          ],
        ),
      ),
    );
  }
}
