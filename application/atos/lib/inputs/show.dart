//분석 결과를 보여주는 페이지

import 'dart:convert';
import 'package:atos/inputs/graph.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:atos/control/uri.dart';

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
  String resultDownloadURL = '';
  String ttsDownloadURL = '';
  String userDownloadURL = '';

  String jsonData = '';

  //그래프 그릴 때 넘겨줄 데이터
  List<FlSpot> userGraphData = [];
  List<FlSpot> ttsGraphData = [];
  List<FlSpot> previousUserGraphData = [];
  List<FlSpot> previousTtsGraphData = [];
  List<FlSpot> userAmplitudeGraphData = [];
  List<FlSpot> ttsAmplitudeGraphData = [];

  //분석 결과에서 받아온 데이터
  List<dynamic> userIntervals = [];
  List<dynamic> ttsIntervals = [];
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
  bool twoGraphs = false;

  //화살표
  final List<Icon> arrows = [
    Icon(Icons.arrow_upward, color: Colors.red, size: 20),
    Icon(Icons.arrow_downward, color: Colors.red, size: 20),
    Icon(Icons.arrow_upward, color: Colors.blue, size: 20),
    Icon(Icons.arrow_downward, color: Colors.blue, size: 20),
  ];
  //final AudioPlayer _audioPlayer = AudioPlayer();
  var title = ''; //연습을 저장할 거라면 연습 제목이 필요함

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  //Map<String, dynamic> jsonData = {}; //분석 결과

  //저장할 연습 제목을 입력받는 팝업
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

  @override
  void initState() {
    fetchResultAndAudios();
    super.initState();
  }

  Future<void> fetchResultAndAudios() async {
    await readJsonData();
  }

  //연습을 저장할 때
  Future<void> saveResult() async {
    try {
      if (title.isEmpty) {
        debugPrint('제목이 비어 있습니다. 저장하지 않습니다.');
        return;
      }

      //제목이 있으면 저장api 호출
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

  Future<void> readJsonData() async {
    try {
      // HTTP GET 요청으로 JSON 데이터 다운로드
      final response = await http.get(
        Uri.parse('${ControlUri.BASE_URL}/get-analysis-data/${widget.result}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          jsonData = response.body;
        });
      } else {
        debugPrint('HTTP 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('데이터 처리 중 오류 발생: $e');
    }

    try {
      // json 파일을 읽어와서 Map으로 변환
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // 분석 결과를 변수에 저장
      setState(() {
        userIntervals = data['word_intervals'] ?? [];
        ttsIntervals = data['tts_word_intervals'] ?? [];
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
        pitchComparisons = (data['comp_pitch_result'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            []; // If null, assign an empty list
        amplitudeComparisons = (data['comp_amp_result'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            []; // If null, assign an empty list
      });
    } catch (e) {
      debugPrint('JSON 데이터 읽기 중 오류 발생: $e');
    }
  }

//타임스탬프를 파싱
  Future<List<Widget>> parseWordIntervals() async {
    try {
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

                      currentResults = results[i];
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
                  angle: -45 * 3.1415927 / 180, // 45도 회전 (라디안 단위)
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
                      ))));
              break;
          }
        }

        wordButtons.add(
          Column(
            children: [
              //텍스트버튼을 만듦
              TextButton(
                onPressed: () {
                  //피치 그래프 업데이트
                  twoGraphs = false;
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
            ],
          ),
        );

        //단어 사이가 표준어 대비 얼마나 위로 혹은 아래로 차이가 나는지 묘사
        //괜찮다면 표시하지 않지만 아래로 차이가 나면 아래로 화살표, 위로 차이가 나면 위로 화살표
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
    double userStart,
    double userEnd,
    double ttsStart,
    double ttsEnd,
  ) {
    userGraphData = [];
    ttsGraphData = [];
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
        title: Text('분석 결과'),
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
                                userAudioPath: widget.userAudio,
                                ttsAudioPath: widget.ttsAudio,
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
                              )
                            : GraphPage(
                                userGraphData: userGraphData,
                                ttsGraphData: ttsGraphData,
                                userAmplitudeGraphData: userAmplitudeGraphData,
                                ttsAmplitudeGraphData: ttsAmplitudeGraphData,
                                userAudioPath: widget.userAudio,
                                ttsAudioPath: widget.ttsAudio,
                                currentUserStart: currentuserStart,
                                currentUserEnd: currentuserEnd,
                                currentTtsStart: currentttsStart,
                                currentTtsEnd: currentttsEnd,
                                pitchFeedback: currentPitchComparison,
                                amplitudeFeedback: currentAmplitudeComparison,
                                previousPitchFeedback: currentResults,
                              ),
                  ),
                  Wrap(
                    spacing: 0.0,
                    children: wordButtons,
                  ),
                  ElevatedButton(onPressed: null, child: Text('연습하기')),
                  ElevatedButton(
                    onPressed: showTitleInputDialog,
                    child: const Text('연습 저장하기'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(
                          context, ModalRoute.withName('/manage'));
                    },
                    child: const Text('돌아가기'),
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
