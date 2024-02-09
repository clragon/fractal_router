import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TimeAliveWidget extends StatefulWidget {
  const TimeAliveWidget({super.key});

  @override
  State<TimeAliveWidget> createState() => _TimeAliveWidgetState();
}

class _TimeAliveWidgetState extends State<TimeAliveWidget>
    with TickerProviderStateMixin {
  final DateTime _startTime = DateTime.now();
  Duration _elapsedTime = Duration.zero;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_updateTime)..start();
  }

  void _updateTime(Duration duration) {
    setState(() {
      _elapsedTime = DateTime.now().difference(_startTime);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    String hours = twoDigits(_elapsedTime.inHours.remainder(24));
    String minutes = twoDigits(_elapsedTime.inMinutes.remainder(60));
    String seconds = twoDigits(_elapsedTime.inSeconds.remainder(60));
    String millis = threeDigits(_elapsedTime.inMilliseconds.remainder(1000));
    return Center(
      child: Text('$hours:$minutes:$seconds.$millis'),
    );
  }
}
