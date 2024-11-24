import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    super.key,
    required this.id,
    required this.title,
    required this.sentence,
    required this.path,
  });
  final String id;
  final String title;
  final String sentence;
  final String path;

  @override
  State<ContentPage> createState() => ContentState();
}

class ContentState extends State<ContentPage> {
  String resultFilePath = "";
  String recordedFilePath = ""; // 녹음된 파일 경로 저장
  String standardFilePath = ""; // TTS 파일 경로 저장

  String resultDownloadURL = '';
  String ttsDownloadURL = '';
  String userDownloadURL = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _audioPlayer = AudioPlayer();

  String jsonData = '';
  List<FlSpot> chartData = [];
  List<FlSpot> userGraphData = [];
  List<FlSpot> ttsGraphData = [];
  List<double> userPitchValues = [];
  List<double> ttsPitchValues = [];
  List<double> userTimeSteps = [];
  List<double> ttsTimeSteps = [];

  @override
  void initState() {
    fetchResultAndAudios();
    super.initState();
  }

  Future<void> fetchResultAndAudios() async {
    await setDownloadUrl();
    await downloadAndSave();
    await readJsonData();
  }

  Future<void> setDownloadUrl() async {
    try {
      String resultUrl = await _storage
          .ref()
          .child(widget.path)
          .child('analysis.json')
          .getDownloadURL();
      String ttsUrl = await _storage
          .ref()
          .child(widget.path)
          .child('ttsVoice.wav')
          .getDownloadURL();
      String userUrl = await _storage
          .ref()
          .child(widget.path)
          .child('userVoice.wav')
          .getDownloadURL();
      setState(() {
        resultDownloadURL = resultUrl;
        ttsDownloadURL = ttsUrl;
        userDownloadURL = userUrl;
      });
    } catch (e) {
      debugPrint("다운로드 링크 오류: $e");
    }
  }

  Future<void> downloadAndSave() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      resultFilePath = '${directory.path}/analysis.json';
      standardFilePath = '${directory.path}/ttsVoice.wav';
      recordedFilePath = '${directory.path}/userVoice.wav';

      await Dio().download(resultDownloadURL, resultFilePath);
      await Dio().download(ttsDownloadURL, standardFilePath);
      await Dio().download(userDownloadURL, recordedFilePath);
    } catch (e) {
      debugPrint("파일 다운로드 오류: $e");
    }
  }

  Future<void> readJsonData() async {
    try {
      final file = File(resultFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          jsonData = contents;
        });

        // Decode the JSON string into a Map
        final Map<String, dynamic> data = jsonDecode(jsonData);

        // Safely retrieve the arrays from the decoded data and cast them to List<double>
        setState(() {
          userTimeSteps = (data['time_steps'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
          ttsTimeSteps = (data['time_steps_tts'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
          userPitchValues = (data['pitch_values'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
          ttsPitchValues = (data['pitch_values_tts'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
        });
      } else {
        debugPrint('JSON 파일이 존재하지 않습니다.');
      }
    } catch (e) {
      debugPrint('JSON 데이터 읽기 중 오류 발생: $e');
    }
  }

// parseWordIntervals() 함수 수정 - 각 단어에 대해 "표준어 들어보기"와 "내 목소리 들어보기" 버튼 추가
  Future<List<Widget>> parseWordIntervals() async {
    try {
      final file = File(resultFilePath);
      if (!await file.exists()) {
        throw 'JSON 파일이 존재하지 않습니다.';
      }
      final contents = await file.readAsString();
      final data = jsonDecode(contents);

      final List<dynamic> userIntervals = data['word_intervals'] ?? [];
      final List<dynamic> ttsIntervals = data['tts_word_intervals'] ?? [];

      if (userIntervals.isEmpty || ttsIntervals.isEmpty) {
        throw 'word_intervals 또는 tts_word_intervals 데이터가 비어 있습니다.';
      }

      List<Widget> wordButtons = [];

      for (int i = 0; i < userIntervals.length; i++) {
        final userInterval = userIntervals[i];
        final ttsInterval = ttsIntervals.length > i ? ttsIntervals[i] : null;

        final String word = userInterval['word'];
        final double userStart = userInterval['start'];
        final double userEnd = userInterval['end'];
        final double ttsStart = ttsInterval?['start'] ?? 0.0;
        final double ttsEnd = ttsInterval?['end'] ?? 0.0;

        wordButtons.add(
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _updateGraphData(userStart, userEnd, ttsStart, ttsEnd);
                },
                child: Text(word),
              ),
              // 표준어 들어보기 버튼
              ElevatedButton(
                onPressed: () {
                  _playSegment(standardFilePath, ttsStart, ttsEnd);
                },
                child: Text("표준어 들어보기"),
              ),
              // 내 목소리 들어보기 버튼
              ElevatedButton(
                onPressed: () {
                  _playSegment(recordedFilePath, userStart, userEnd);
                },
                child: Text("내 목소리 들어보기"),
              ),
            ],
          ),
        );
      }

      return wordButtons;
    } catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      return [];
    }
  }

  Future<void> _playSegment(String path, double start, double end) async {
    await _audioPlayer.play(
      DeviceFileSource(path),
      position: Duration(milliseconds: (start * 1000).toInt()),
    );
    Timer(Duration(milliseconds: ((end - start) * 1000).toInt()), () async {
      await _audioPlayer.stop();
    });
  }

  // 피치 데이터를 기준으로 그래프를 업데이트하는 함수
  void _updateGraphData(
      double userStart, double userEnd, double ttsStart, double ttsEnd) {
    // 예시로 시간 범위 내에서 유저와 TTS의 피치 데이터를 불러와서 사용
    // 실제로는 userStart, userEnd, ttsStart, ttsEnd에 해당하는 피치 데이터를 가져와야 함

    print(userStart);
    print(userEnd);
    print(ttsStart);
    print(ttsEnd);
    userGraphData = [];
    ttsGraphData = [];

    // 유저 피치 값 (예시)
    for (int i = 0; i < userTimeSteps.length; i++) {
      if (userTimeSteps[i] >= userStart &&
          userTimeSteps[i] <= userEnd &&
          userPitchValues[i] != 0) {
        userGraphData
            .add(FlSpot(userTimeSteps[i] - userStart, userPitchValues[i]));
      }
    }

    // TTS 피치 값 (예시)
    for (int i = 0; i < ttsTimeSteps.length; i++) {
      if (ttsTimeSteps[i] >= ttsStart &&
          ttsTimeSteps[i] <= ttsEnd &&
          ttsPitchValues[i] != 0) {
        ttsGraphData.add(FlSpot(ttsTimeSteps[i] - ttsStart, ttsPitchValues[i]));
      }
    }

    print(ttsGraphData.length);

    setState(() {
      chartData = [
        ...userGraphData,
        ...ttsGraphData,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder(
        future: parseWordIntervals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text('데이터를 가지고 오는 중입니다.'));
          } else {
            final wordButtons = snapshot.data as List<Widget>;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: wordButtons,
                  ),
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: chartData.isEmpty
                        ? Center(child: Text('단어를 선택하세요'))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                    spots: userGraphData,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 4,
                                    dotData: FlDotData(show: false)),
                                LineChartBarData(
                                    spots: ttsGraphData,
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 4,
                                    dotData: FlDotData(show: false)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
