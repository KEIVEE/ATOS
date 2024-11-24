import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:atos/control/uri.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  var title = '';

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> jsonData = {};

  Future<void> showTitleInputDialog() async {
    final TextEditingController titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('제목 입력'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: '제목을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  title = titleController.text; // 입력한 제목 저장
                });
                saveResult(); // 연습목록에 추가
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playAudio(String path) async {
    try {
      // 오디오 플레이어를 통해 음성 파일 재생
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint("오디오 재생 오류: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getZip();
  }

  Future<void> saveResult() async {
    try {
      if (title.isEmpty) {
        debugPrint('제목이 비어 있습니다. 저장하지 않습니다.');
        return;
      }

      final response = await http.post(
        Uri.parse('${ControlUri.BASE_URL}/save-user-practice'),
        headers: headers,
        body: jsonEncode(
          {
            "user_id": widget.id,
            "temp_id": widget.result,
            "title": title,
          },
        ),
      );

      debugPrint(jsonEncode({
        "user_id": widget.id,
        "temp_id": widget.result,
        "title": title,
      }));

      if (response.statusCode == 200) {
        debugPrint('데이터가 성공적으로 업로드되었습니다.');
      } else {
        debugPrint('HTTP 요청 실패: ${response.statusCode}');
        debugPrint('HTTP 요청 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('데이터 처리 중 오류 발생: $e');
    }
  }

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

          print(jsonData['results']);

          print(jsonData);
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
                onPressed: () {
                  _playAudio(widget.ttsAudio);
                },
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                child: const Text('표준어 듣기')),
            OutlinedButton(
                onPressed: () {
                  _playAudio(widget.userAudio);
                },
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
              onPressed: () {
                showTitleInputDialog();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('연습목록에 추가'),
            ),

            Text(jsonData['results'].toString()),
            const Text('양옆으로 바꿀 거임. 아니면 양옆 늘려서 이대로 가던가, 아이콘으로 바꾸던가?'),
            // OutlinedButton(
            //     onPressed: getZip,
            //     style: OutlinedButton.styleFrom(
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(10.0))),
            //     child: const Text('zip파일 테스트')),
          ],
        ),
      ),
    );
  }
}
