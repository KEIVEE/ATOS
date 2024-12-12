//저장된 연습의 분석 결과를 불러오는 페이지

import 'dart:async';
import 'package:atos/control/ui.dart';
import 'package:atos/inputs/graph.dart';
import 'package:atos/practice/try.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    super.key,
    required this.id,
    required this.title,
    required this.sentence,
  });
  final String id;
  final String title;
  final String sentence;

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
  bool twoGraphs = false;

  String jsonData = '';

  //그래프 그릴 때 넘겨줄 데이터
  List<FlSpot> userGraphData = [];
  List<FlSpot> ttsGraphData = [];
  List<FlSpot> previousUserGraphData = [];
  List<FlSpot> previousTtsGraphData = [];
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
  List<int> pitchComparisons = [];
  List<int> amplitudeComparisons = [];
  int userSamplingRate = 0;
  int ttsSamplingRate = 0;

  double maxPitch = 0;
  double minPitch = 0;
  int maxAmp = 0;

  //선택된 단어의 시작점과 끝점, 담을 메시지
  double currentuserStart = 0.0;
  double currentuserEnd = 0.0;
  double currentttsStart = 0.0;
  double currentttsEnd = 0.0;
  double previousUserStart = 0.0;
  double previousUserEnd = 0.0;
  double previousTtsStart = 0.0;
  double previousTtsEnd = 0.0;
  int currentPitchComparison = 0;
  int currentAmplitudeComparison = 0;
  int currentResults = 0;

  //화살표
  final List<Icon> arrows = [
    Icon(Icons.arrow_upward, color: Colors.red, size: 20),
    Icon(Icons.arrow_downward, color: Colors.red, size: 20),
    Icon(Icons.arrow_upward, color: Colors.blue, size: 20),
    Icon(Icons.arrow_downward, color: Colors.blue, size: 20),
  ];

  @override
  void initState() {
    fetchResultAndAudios();
    super.initState();
  }

  Future<void> fetchResultAndAudios() async {
    await downloadAndSave();
    await readJsonData();
  }

  //파일 다운로드. json, tts, userVoice 파일 모두 다운 받는다
  Future<void> downloadAndSave() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      resultFilePath = '${directory.path}/${widget.title}/analysis.json';
      standardFilePath = '${directory.path}/${widget.title}/ttsVoice.wav';
      recordedFilePath = '${directory.path}/${widget.title}/userVoice.wav';

      //await Dio().download(resultDownloadURL, resultFilePath);
      //await Dio().download(ttsDownloadURL, standardFilePath);
      //await Dio().download(userDownloadURL, recordedFilePath);
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
          maxPitch = (data['max_pitch'] as num?)?.toDouble() ?? 0;
          minPitch = (data['min_pitch'] as num?)?.toDouble() ?? 0;
          maxAmp = (data['max_amp'] as num?)?.toInt() ?? 0;
          results = (data['results'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              []; // If null, assign an empty list
          debugPrint(results.toString());
          pitchComparisons = (data['comp_pitch_result'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              []; // If null, assign an empty list
          amplitudeComparisons = (data['comp_amp_result'] as List<dynamic>?)
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

        if (i > 0) {
          switch (results[i - 1]) {
            case 0:
              wordButtons.add(SizedBox(width: 20));
              break;
            case 1:
              wordButtons.add(IconButton(
                  onPressed: () {
                    setState(() {
                      //진폭 그래프 업데이트
                      twoGraphs = true;
                      previousUserStart = userIntervals[i - 1]['start'];
                      previousTtsStart = ttsIntervals[i - 1]['start'];
                      previousUserEnd = userIntervals[i - 1]['end'];
                      previousTtsEnd = ttsIntervals[i - 1]['end'];
                      userAmplitudeGraphData = generateUserAmplitudeData(
                          userAmplitudeValues,
                          userSamplingRate,
                          previousUserStart,
                          userEnd);
                      ttsAmplitudeGraphData = generateTtsAmplitudeData(
                          ttsAmplitudeValues,
                          ttsSamplingRate,
                          previousTtsStart,
                          ttsEnd);

                      //선택된 단어 시작점 끝점 업데이트
                      currentuserStart = userStart;
                      currentuserEnd = userEnd;
                      currentttsStart = ttsStart;
                      currentttsEnd = ttsEnd;

                      //메시지를 담음
                      currentPitchComparison = 0;
                      currentAmplitudeComparison = 0;

                      if (i > 0) {
                        currentResults = results[i - 1];
                      } else {
                        currentResults = 0;
                      }
                    });
                    _updatePreviousGraphData(
                        previousUserStart,
                        previousUserEnd,
                        previousTtsStart,
                        previousTtsEnd,
                        userStart,
                        userEnd,
                        ttsStart,
                        ttsEnd);
                  },
                  icon: Icon(
                    Icons.arrow_outward,
                    color: Colors.orange,
                    size: 20,
                  )));
              break;
            case -1:
              wordButtons.add(Transform.rotate(
                  angle: 90 * 3.1415927 / 180, // 45도 회전 (라디안 단위)
                  child: IconButton(
                      onPressed: () {
                        setState(() {
                          //진폭 그래프 업데이트
                          twoGraphs = true;
                          previousUserStart = userIntervals[i - 1]['start'];
                          previousTtsStart = ttsIntervals[i - 1]['start'];
                          previousUserEnd = userIntervals[i - 1]['end'];
                          previousTtsEnd = ttsIntervals[i - 1]['end'];
                          userAmplitudeGraphData = generateUserAmplitudeData(
                              userAmplitudeValues,
                              userSamplingRate,
                              previousUserStart,
                              userEnd);
                          ttsAmplitudeGraphData = generateTtsAmplitudeData(
                              ttsAmplitudeValues,
                              ttsSamplingRate,
                              previousTtsStart,
                              ttsEnd);

                          //선택된 단어 시작점 끝점 업데이트
                          currentuserStart = userStart;
                          currentuserEnd = userEnd;
                          currentttsStart = ttsStart;
                          currentttsEnd = ttsEnd;

                          //메시지를 담음
                          currentPitchComparison = 0;
                          currentAmplitudeComparison = 0;

                          currentResults = results[i - 1];
                        });
                        _updatePreviousGraphData(
                            previousUserStart,
                            previousUserEnd,
                            previousTtsStart,
                            previousTtsEnd,
                            userStart,
                            userEnd,
                            ttsStart,
                            ttsEnd);
                      },
                      icon: Icon(
                        Icons.arrow_outward,
                        color: Colors.orange,
                        size: 20,
                      ))));
              break;
          }
        }

        wordButtons.add(
          Column(
            children: [
              //텍스트버튼을 만듦
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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

                    //메시지를 담음
                    currentPitchComparison = pitchComparisons[i];
                    currentAmplitudeComparison = amplitudeComparisons[i];

                    currentResults = 0;
                  });
                },
                child: Text(word, style: const TextStyle(fontSize: 20)),
              ),
              SizedBox(
                height: 10,
                width: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (pitchComparisons[i] == 1) arrows[0],
                    if (pitchComparisons[i] == -1) arrows[1],
                    if (amplitudeComparisons[i] == 1) arrows[2],
                    if (amplitudeComparisons[i] == -1) arrows[3]
                  ],
                ),
              ),
              SizedBox(height: 50),
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
    previousTtsGraphData = [];
    previousUserGraphData = [];
    //print(userStart);
    //print(ttsStart);

    // 유저 피치 값
    for (int i = 0; i < userTimeSteps.length; i++) {
      if (userTimeSteps[i] >= userStart &&
          userTimeSteps[i] <= userEnd &&
          userPitchValues[i] != 0) {
        //print(userTimeSteps[i]);
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

  void _updatePreviousGraphData(
    double previousUserStart,
    double previousUserEnd,
    double previousTtsStart,
    double previousTtsEnd,
    double userStart,
    double userEnd,
    double ttsStart,
    double ttsEnd,
  ) {
    previousUserGraphData = [];
    previousTtsGraphData = [];
    userGraphData = [];
    ttsGraphData = [];
    //print(userStart);
    //print(ttsStart);

    // 유저 피치 값
    for (int i = 0; i < userTimeSteps.length; i++) {
      if (userTimeSteps[i] >= previousUserStart &&
          userTimeSteps[i] <= previousUserEnd &&
          userPitchValues[i] != 0) {
        //print(userTimeSteps[i]);
        previousUserGraphData.add(FlSpot(userTimeSteps[i], userPitchValues[i]));
      } else if (userTimeSteps[i] >= userStart &&
          userTimeSteps[i] <= userEnd &&
          userPitchValues[i] != 0) {
        //print(userTimeSteps[i]);
        userGraphData.add(FlSpot(userTimeSteps[i], userPitchValues[i]));
      }
    }

    for (int i = 0; i < ttsTimeSteps.length; i++) {
      if (ttsTimeSteps[i] >= previousTtsStart &&
          ttsTimeSteps[i] <= previousTtsEnd &&
          ttsPitchValues[i] != 0) {
        previousTtsGraphData.add(FlSpot(ttsTimeSteps[i], ttsPitchValues[i]));
      } else if (ttsTimeSteps[i] >= ttsStart &&
          ttsTimeSteps[i] <= ttsEnd &&
          ttsPitchValues[i] != 0) {
        ttsGraphData.add(FlSpot(ttsTimeSteps[i], ttsPitchValues[i]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                    height: 550,
                    width: double.infinity,
                    child: userGraphData.isEmpty
                        ? Center(child: Text('단어를 선택하세요'))
                        //그래프 보여주는 내부 페이지 호출
                        : twoGraphs
                            ? GraphPage(
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
                                pitchFeedback: currentPitchComparison,
                                amplitudeFeedback: currentAmplitudeComparison,
                                previousPitchFeedback: currentResults,
                                previousUserGraphData: previousUserGraphData,
                                previousTtsGraphData: previousTtsGraphData,
                                previousTtsEnd: previousTtsEnd,
                                previousTtsStart: previousTtsStart,
                                previousUserEnd: previousUserEnd,
                                previousUserStart: previousUserStart,
                                maxPitch: maxPitch,
                                minPitch: minPitch,
                                maxAmp: maxAmp,
                              )
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
                                pitchFeedback: currentPitchComparison,
                                amplitudeFeedback: currentAmplitudeComparison,
                                previousPitchFeedback: currentResults,
                                maxPitch: maxPitch,
                                minPitch: minPitch,
                                maxAmp: maxAmp,
                              ),
                  ),
                  Wrap(
                    spacing: 0.0,
                    children: wordButtons,
                  ),
                  SizedBox(height: 20),
                  CustomedButton(
                    text: '연습하기',
                    textColor: Colors.white,
                    buttonColor: Theme.of(context).primaryColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: "/translating"),
                          builder: (context) => TryPage(
                            id: widget.id,
                            title: widget.title,
                            sentence: widget.sentence,
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
