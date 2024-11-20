import 'dart:convert';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:atos/inputs/translated.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TranslatingPage extends StatefulWidget {
  const TranslatingPage({
    super.key,
    required this.id,
    required this.inputText,
    required this.todo,
  });

  final String id;
  final String inputText;
  final String todo;

  @override
  State<TranslatingPage> createState() => TranslatingState();
}

class TranslatingState extends State<TranslatingPage> {
  var region = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchRegionAndProcessRequest();
  }

  Future<void> _fetchRegionAndProcessRequest() async {
    await _fetchRegion();
    await _processRequest();
  }

  Future<void> _fetchRegion() async {
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await db.collection('userData').doc(widget.id).get();
      setState(() {
        region = userDoc['region'] ?? ' ';
      });
    }
  }

  Future<void> _processRequest() async {
    try {
      final response = await http.post(
        Uri.parse('${ControlUri.BASE_URL}/translate-text'),
        body: json.encode({
          'text': widget.inputText,
          'user_id': widget.id,
          'region': region,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint(responseData.toString());
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/translated"),
              builder: (context) => TranslatedPage(
                id: widget.id,
                translatedText: responseData['translated_text_data'],
                audioName: responseData['audio_title'],
              ),
            ),
          );
        }
      } else {
        debugPrint("오류 발생: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("HTTP 요청 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // 뒤로 가기 동작 비활성화
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(widget.todo),
              SizedBox(height: 10),
              SizedBox(
                width: 100, // 원하는 너비
                height: 100, // 원하는 높이
                child: CircularProgressIndicator(
                  strokeWidth: 10, // 두께 조절
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
