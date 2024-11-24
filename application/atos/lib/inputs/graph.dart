import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphPage extends StatefulWidget {
  final List<FlSpot> userGraphData;
  final List<FlSpot> ttsGraphData;
  final List<FlSpot> userAmplitudeGraphData;
  final List<FlSpot> ttsAmplitudeGraphData;
  final double currentUserStart;
  final double currentUserEnd;
  final double currentTtsStart;
  final double currentTtsEnd;
  final String userAudioPath;
  final String ttsAudioPath;

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
              icon: SizedBox.shrink(),
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
          selectedItemColor: const Color.fromARGB(255, 118, 130, 197),
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