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
    super.initState();
    print(widget.userAudioPath);
    print(widget.currentTtsEnd);
    print(widget.currentTtsStart);

    //그래프 데이터 설정
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
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ElevatedButton(
            onPressed: () {
              _playSegment(widget.ttsAudioPath, widget.currentTtsStart,
                  widget.currentTtsEnd);
            },
            child: Text("표준어 들어보기"),
          ),
          // 내 목소리 들어보기 버튼
          ElevatedButton(
            onPressed: () {
              _playSegment(widget.userAudioPath, widget.currentUserStart,
                  widget.currentUserEnd);
            },
            child: Text("내 목소리 들어보기"),
          ),
          //Text(widget.userAudioPath),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory, // 물방울 애니메이션 제거
        ),
        child: BottomNavigationBar(
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
            ttsPitchGraph,
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
