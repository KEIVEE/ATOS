//그래프를 보여주는 페이지. content.dart와 show.dart의 내부에서 사용되는 페이지임
//그래프는 단어 하나하나마다 보여줌

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphPage extends StatefulWidget {
  final List<FlSpot> userGraphData; //사용자의 pitch 데이터로 만든 그래프 지점
  final List<FlSpot> ttsGraphData; //표준어의 pitch 데이터로 만든 그래프 지점
  final List<FlSpot> userAmplitudeGraphData; //사용자의 amplitude 데이터로 만든 그래프 지점
  final List<FlSpot> ttsAmplitudeGraphData; //표준어의 amplitude 데이터로 만든 그래프 지점
  final double currentUserStart; //사용자의 해당 단어 타임스탬프 시작점
  final double currentUserEnd; //사용자의 해당 단어 타임스탬프 끝점
  final double currentTtsStart; //표준어의 해당 단어 타임스탬프 시작점
  final double currentTtsEnd; //표준어의 해당 단어 타임스탬프 끝점
  final String userAudioPath; //사용자의 음성 파일 경로
  final String ttsAudioPath; //표준어의 음성 파일 경로
  final int pitchFeedback; //피치 피드백
  final int amplitudeFeedback; //진폭 피드백
  final int previousPitchFeedback; //이전 단어 피치 피드백
  final double? previousUserStart; //이전 단어 사용자 타임스탬프 시작점
  final double? previousUserEnd; //이전 단어 사용자 타임스탬프 끝점
  final double? previousTtsStart; //이전 단어 표준어 타임스탬프 시작점
  final double? previousTtsEnd; //이전 단어 표준어 타임스탬프 끝점
  final List<FlSpot>? previousUserGraphData; //이전 단어 사용자 pitch 데이터로 만든 그래프 지점
  final List<FlSpot>? previousTtsGraphData; //이전 단어 표준어 pitch 데이터로 만든 그래프 지점
  final List<FlSpot>?
      previousUserAmplitudeGraphData; //이전 단어 사용자 amplitude 데이터로 만든 그래프 지점
  final List<FlSpot>?
      previousTtsAmplitudeGraphData; //이전 단어 표준어 amplitude 데이터로 만든 그래프 지점

  const GraphPage({
    super.key,
    required this.userGraphData,
    required this.ttsGraphData,
    required this.userAmplitudeGraphData,
    required this.ttsAmplitudeGraphData,
    required this.currentUserStart,
    required this.currentUserEnd,
    required this.currentTtsStart,
    required this.currentTtsEnd,
    required this.userAudioPath,
    required this.ttsAudioPath,
    required this.pitchFeedback,
    required this.amplitudeFeedback,
    required this.previousPitchFeedback,
    this.previousUserStart,
    this.previousUserEnd,
    this.previousTtsStart,
    this.previousTtsEnd,
    this.previousUserGraphData,
    this.previousTtsGraphData,
    this.previousUserAmplitudeGraphData,
    this.previousTtsAmplitudeGraphData,
  });

  @override
  GraphState createState() => GraphState();
}

class GraphState extends State<GraphPage> {
  int _selectedIndex = 0;

  late LineChartBarData userPitchGraph;
  late LineChartBarData ttsPitchGraph;
  late LineChartBarData userAmplitudeGraph;
  late LineChartBarData ttsAmplitudeGraph;
  late LineChartBarData? previousUserPitchGraph;
  late LineChartBarData? previousTtsPitchGraph;

  final _audioPlayer = AudioPlayer();

  //구간만 재생하는 함수
  Future<void> _playSegment(String path, double start, double end) async {
    await _audioPlayer.play(
      DeviceFileSource(path),
      position: Duration(milliseconds: (start * 1000).toInt()),
    );
    Timer(Duration(milliseconds: ((end - start) * 1000).toInt()), () async {
      await _audioPlayer.stop();
    });
  }

  @override
  void initState() {
    userPitchGraph = LineChartBarData(
      spots: widget.userGraphData,
      isCurved: true,
      color: Colors.blue,
      barWidth: 4,
      dotData: FlDotData(show: false),
    );
    ttsPitchGraph = LineChartBarData(
      spots: widget.ttsGraphData,
      isCurved: true,
      color: Colors.red,
      barWidth: 4,
      dotData: FlDotData(show: false),
    );
    userAmplitudeGraph = LineChartBarData(
      spots: widget.userAmplitudeGraphData,
      isCurved: true,
      color: Colors.blue,
      barWidth: 1,
      dotData: FlDotData(show: false),
    );
    ttsAmplitudeGraph = LineChartBarData(
      spots: widget.ttsAmplitudeGraphData,
      isCurved: true,
      color: Colors.red,
      barWidth: 1,
      dotData: FlDotData(show: false),
    );
    previousTtsPitchGraph = widget.previousTtsGraphData != null
        ? LineChartBarData(
            spots: widget.previousTtsGraphData!,
            isCurved: true,
            color: Colors.red,
            barWidth: 4,
            dotData: FlDotData(show: false),
          )
        : null;
    previousUserPitchGraph = widget.previousUserGraphData != null
        ? LineChartBarData(
            spots: widget.previousUserGraphData!,
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            dotData: FlDotData(show: false),
          )
        : null;
    super.initState();
    //그래프 데이터 설정
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, '유저'),
                SizedBox(width: 16),
                _buildLegendItem(Colors.red, '표준어'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _getWidgetOptions().elementAt(_selectedIndex),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (previousTtsPitchGraph != null) {
                    _playSegment(widget.ttsAudioPath, widget.previousTtsStart!,
                        widget.currentTtsEnd);
                  } else {
                    _playSegment(widget.ttsAudioPath, widget.currentTtsStart,
                        widget.currentTtsEnd);
                  }
                },
                child: Text("표준어 들어보기"),
              ),
              SizedBox(width: 16),
              // 내 목소리 들어보기 버튼
              ElevatedButton(
                onPressed: () {
                  if (previousUserPitchGraph != null) {
                    _playSegment(widget.userAudioPath,
                        widget.previousUserStart!, widget.currentUserEnd);
                  } else {
                    _playSegment(widget.userAudioPath, widget.currentUserStart,
                        widget.currentUserEnd);
                  }
                },
                child: Text("내 목소리 들어보기"),
              ),
            ],
          ),
          SizedBox(
            //color: Colors.grey,
            child: Column(
              children: [
                if (widget.pitchFeedback == 1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '표준어에 비해 높낮이 변화가 커요.\n더 부드럽게 발음해보세요.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.pitchFeedback == -1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '표준어에 비해 높낮이 변화가 작아요.\n더 다양한 톤으로 발음해보세요.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.amplitudeFeedback == 1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '표준어에 비해 음량 변화가 커요.\n더 부드럽게 발음해보세요.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.amplitudeFeedback == -1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '표준어에 비해 음량 변화가 작아요.\n더 다양한 음량으로 발음해보세요.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.previousPitchFeedback == 1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '이전 단어보다 너무 높아졌어요.\n좀 더 낮춰서 발음해보세요.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.previousPitchFeedback == -1)
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 테두리를 둥글게 설정
                    ),
                    //color: Colors.grey,
                    child: Text(
                      '이전 단어보다 너무 낮아졌어요.\n좀 더 높여서 발음해보세요.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          //Text(widget.userAudioPath),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory, // 물방울 애니메이션 제거
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: SizedBox.shrink(), // 아이콘 없음
              label: '피치 그래프',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: '진폭 그래프',
            ),
          ],
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
          currentIndex: _selectedIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          selectedItemColor: Colors.indigo,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  List<Widget> _getWidgetOptions() {
    return <Widget>[
      LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            userPitchGraph,
            if (previousTtsPitchGraph != null) previousTtsPitchGraph!,
            ttsPitchGraph,
            if (previousUserPitchGraph != null) previousUserPitchGraph!,
          ],
        ),
      ),
      LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          // y = 0이 중앙에 오도록 설정
          maxY: 20000,
          minY: -20000,
          lineBarsData: [
            userAmplitudeGraph,
            ttsAmplitudeGraph,
          ],
        ),
      ),
    ];
  }
}
