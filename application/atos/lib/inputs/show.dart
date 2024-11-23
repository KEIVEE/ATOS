import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:atos/control/uri.dart';

// 화면들을 모아놓는? 페이지. 아래 버튼들 클릭하면 해당 화면으로 이동하도록.

class ShowPage extends StatefulWidget {
  const ShowPage(
      {super.key,
      required this.ttsAudio,
      required this.id,
      required this.text,
      required this.userAudio,
      required this.result});

  final String id;
  final String ttsAudio;
  final String userAudio;
  final String text;
  final String result;

  @override
  State<ShowPage> createState() => ShowState();
}

class ShowState extends State<ShowPage> {
  Map<String, String> headers = {
    'Accept': 'application/json',
  };
  Future<void> getZip() async {
    try {
      // HTTP GET 요청으로 JSON 데이터 다운로드
      final response = await http.get(
        Uri.parse('${ControlUri.BASE_URL}/get-analysis-data/${widget.result}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        try {
          // 응답 데이터 가져오기
          String jsonString = response.body;
          print(jsonString.length);

          // JSON 파싱
          Map<String, dynamic> jsonData = jsonDecode(jsonString);
          //debugPrint('JSON 데이터: $jsonData');

          // 다운로드 디렉토리 경로 가져오기
          // Directory? downloadsDirectory = await getExternalStorageDirectory();
          // if (downloadsDirectory != null) {
          //   String downloadsPath = downloadsDirectory.path;
          //   String filePath = '$downloadsPath/response.json';

          //   // 데이터 파일로 저장
          //   File(filePath).writeAsStringSync(jsonString);
          //   debugPrint('파일이 저장되었습니다: $filePath');
          // } else {
          //   debugPrint('다운로드 디렉토리를 찾을 수 없습니다.');
          // }
        } catch (e) {
          debugPrint('데이터 처리 중 오류 발생: $e');
        }
      } else {
        debugPrint('HTTP 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('데이터 처리 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결과'),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('그래프'),
            Text(widget.result),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('표준어 듣기')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('내 발음 듣기')),
            OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) {
                    return route.settings.name == '/manage'; // HomePage의 경로
                  });
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('홈으로 가기 = 연습목록에 추가하지 않기')),
            OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('연습목록에 추가')),
            const Text('양옆으로 바꿀 거임. 아니면 양옆 늘려서 이대로 가던가, 아이콘으로 바꾸던가?'),
            OutlinedButton(
                onPressed: getZip,
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('zip파일 테스트')),
          ],
        ),
      ),
    );
  }
}
