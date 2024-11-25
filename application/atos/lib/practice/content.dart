//저장된 연습의 분석 결과를 불러오는 페이지

import 'dart:async';
import 'package:atos/inputs/graph.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

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
  String resultFilePath = ""; // json파일 경로
  String recordedFilePath = ""; // 녹음된 파일 경로
  String standardFilePath = ""; // TTS 파일 경로

  String resultDownloadURL = '';
  String ttsDownloadURL = '';
  String userDownloadURL = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String jsonData = '';

  //그래프 그릴 때 넘겨줄 데이터
  List<FlSpot> userGraphData = [];
  List<FlSpot> ttsGraphData = [];
  List<FlSpot> userAmplitudeGraphData = [];
  List<FlSpot> ttsAmplitudeGraphData = [];

  //분석 결과에서 받아온 데이터
  List<double> userPitchValues = [];
  List<double> ttsPitchValues = [];
  List<double> userTimeSteps = [];
  List<double> ttsTimeSteps = [];
  List<double> userAmplitudeValues = [];
  List<double> ttsAmplitudeValues = [];
  List<String> feedbacks = [];
  List<int> results = [];
  int userSamplingRate = 0;
  int ttsSamplingRate = 0;

  //선택된 단어의 시작점과 끝점
  double currentuserStart = 0.0;
  double currentuserEnd = 0.0;
  double currentttsStart = 0.0;
  double currentttsEnd = 0.0;

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

  //파이어스토어에 저장된 파일의 다운로드 URL을 가져오는 함수
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

  //파일 다운로드. json, tts, userVoice 파일 모두 다운 받는다
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

  //json 디코딩
  Future<void> readJsonData() async {
    try {
      final file = File(resultFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        setState(() {
          jsonData = contents;
        });

        // json 파일을 읽어와서 Map으로 변환
        final Map<String, dynamic> data = jsonDecode(jsonData);

        // 분석 결과를 변수에 저장
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
          userAmplitudeValues = (data['filtered_data'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
          ttsAmplitudeValues = (data['tts_data'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              []; // If null, assign an empty list
          userSamplingRate = data['sampling_rate'] as int? ?? 0;
          ttsSamplingRate = data['tts_sampling_rate'] as int? ?? 0;
          results = (data['results'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
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

//타임스탬프를 파싱
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

      //타임스탬프 단어마다,
      for (int i = 0; i < userIntervals.length; i++) {
        final userInterval = userIntervals[i];
        final ttsInterval = ttsIntervals.length > i ? ttsIntervals[i] : null;

        //단어 내용, 시작점, 끝점을 받아오고
        final String word = userInterval['word'];
        final double userStart = userInterval['start'];
        final double userEnd = userInterval['end'];
        final double ttsStart = ttsInterval?['start'] ?? 0.0;
        final double ttsEnd = ttsInterval?['end'] ?? 0.0;

        wordButtons.add(
          Column(
            children: [
              //텍스트버튼을 만듦
              TextButton(
                onPressed: () {
                  //피치 그래프 업데이트
                  _updateGraphData(userStart, userEnd, ttsStart, ttsEnd);
                  setState(() {
                    //진폭 그래프 업데이트
                    userAmplitudeGraphData = generateUserAmplitudeData(
                        userAmplitudeValues,
                        userSamplingRate,
                        userStart,
                        userEnd);
                    ttsAmplitudeGraphData = generateTtsAmplitudeData(
                        ttsAmplitudeValues, ttsSamplingRate, ttsStart, ttsEnd);

                    //선택된 단어 시작점 끝점 업데이트
                    currentuserStart = userStart;
                    currentuserEnd = userEnd;
                    currentttsStart = ttsStart;
                    currentttsEnd = ttsEnd;
                  });
                },
                child: Text(word, style: const TextStyle(fontSize: 20)),
              ),
            ],
          ),
        );

        //단어 사이가 표준어 대비 얼마나 위로 혹은 아래로 차이가 나는지 묘사
        //괜찮다면 표시하지 않지만 아래로 차이가 나면 아래로 화살표, 위로 차이가 나면 위로 화살표
        if (i < results.length) {
          switch (results[i]) {
            case 0:
              wordButtons.add(SizedBox(width: 20));
              break;
            case 1:
              wordButtons.add(Icon(
                Icons.arrow_outward,
                color: Colors.orange,
                size: 20,
              ));
              break;
            case -1:
              wordButtons.add(Transform.rotate(
                angle: -45 * 3.1415927 / 180, // 45도 회전 (라디안 단위)
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.orange,
                  size: 20,
                ),
              ));
              break;
          }
        }
      }

      return wordButtons;
    } catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      return [];
    }
  }

  //사용자의 진폭 그래프 데이터 생성
  List<FlSpot> generateUserAmplitudeData(
      List<double> amplitude, int samplingRate, double start, double end) {
    int sampleStart = (start * samplingRate).toInt();
    int sampleEnd = (end * samplingRate).toInt();
    int length = sampleEnd - sampleStart;

    List<FlSpot> spots = [];
    for (int i = 0; i < length; i++) {
      double value = amplitude[sampleStart + i];
      if (value > 0) {
        //그래프의 시작점을 맞춤. 타임스탬프 시작점이 달라서 그래프가 이상하게 나오는 것을 방지
        spots.add(FlSpot(i / samplingRate, -value));
      }
    }
    return spots;
  }

  //표준어의 진폭 그래프 데이터 생성
  List<FlSpot> generateTtsAmplitudeData(
      List<double> amplitude, int samplingRate, double start, double end) {
    int sampleStart = (start * samplingRate).toInt();
    int sampleEnd = (end * samplingRate).toInt();
    int length = sampleEnd - sampleStart;

    List<FlSpot> spots = [];
    for (int i = 0; i < length; i++) {
      double value = amplitude[sampleStart + i];
      if (value > 0) {
        spots.add(FlSpot(i / samplingRate, value));
      }
    }
    return spots;
  }

  // 피치 데이터를 기준으로 그래프를 업데이트하는 함수
  void _updateGraphData(
      double userStart, double userEnd, double ttsStart, double ttsEnd) {
    userGraphData = [];
    ttsGraphData = [];

    // 유저 피치 값
    for (int i = 0; i < userTimeSteps.length; i++) {
      if (userTimeSteps[i] >= userStart &&
          userTimeSteps[i] <= userEnd &&
          userPitchValues[i] != 0) {
        userGraphData
            .add(FlSpot(userTimeSteps[i] - userStart, userPitchValues[i]));
      }
    }

    // TTS 피치 값
    for (int i = 0; i < ttsTimeSteps.length; i++) {
      if (ttsTimeSteps[i] >= ttsStart &&
          ttsTimeSteps[i] <= ttsEnd &&
          ttsPitchValues[i] != 0) {
        ttsGraphData.add(FlSpot(ttsTimeSteps[i] - ttsStart, ttsPitchValues[i]));
      }
    }
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
                  SizedBox(
                    height: 450,
                    width: double.infinity,
                    child: userGraphData.isEmpty
                        ? Center(child: Text('단어를 선택하세요'))
                        //그래프 보여주는 내부 페이지 호출
                        : GraphPage(
                            userGraphData: userGraphData,
                            ttsGraphData: ttsGraphData,
                            userAmplitudeGraphData: userAmplitudeGraphData,
                            ttsAmplitudeGraphData: ttsAmplitudeGraphData,
                            userAudioPath: recordedFilePath,
                            ttsAudioPath: standardFilePath,
                            currentUserStart: currentuserStart,
                            currentUserEnd: currentuserEnd,
                            currentTtsStart: currentttsStart,
                            currentTtsEnd: currentttsEnd,
                          ),
                  ),
                  Wrap(
                    spacing: 0.0,
                    children: wordButtons,
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
