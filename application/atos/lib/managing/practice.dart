//본인이 저장한 목록을 보여주는 페이지

import 'dart:convert';
import 'package:atos/control/ui.dart';
import 'package:atos/control/uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:atos/practice/titlebutton.dart';

class PracticePage extends StatefulWidget {
  final String id;

  const PracticePage({super.key, required this.id});

  @override
  State<PracticePage> createState() => PracticeState();
}

class PracticeState extends State<PracticePage> {
  late Future<List<dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  //자기 id로 된 목록을 가져옴
  Future<List<dynamic>> _fetchData() async {
    final response = await http.get(
        Uri.parse('${ControlUri.BASE_URL}/get-user-practice/${widget.id}'));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100),
            ManageSizedBox(
              content: Column(
                children: [
                  FutureBuilder<List<dynamic>>(
                    future: _futureData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(children: [
                          SizedBox(height: 100),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(),
                          ),
                        ]);
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text('저장된 데이터가 없습니다.'),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true, // ListView의 크기를 내용에 맞게 조정
                          physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var item = snapshot.data![index];
                            // 데이터 항목을 빌드하는 코드
                            return TitleButton(
                              title: item['title'],
                              sentence: item['text'],
                              id: widget.id,
                              path:
                                  item['data_path'], //firebase storage에 저장된 경로.
                              //분석 json, TTS음성, 유저음성이 담겨 있음
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              boxHeight: 1000,
            ),
          ],
        ),
      ),
    );
  }
}
