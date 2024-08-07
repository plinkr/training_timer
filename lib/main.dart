import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  int _seconds = 180;
  int _totalSeconds = 180;
  int _rounds = 12;
  int _currentRound = 1;
  int _restSeconds = 60;
  bool _isResting = false;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _startPauseTimer() {
    setState(() {
      if (_isRunning) {
        _isPaused = !_isPaused;
        if (_isPaused) {
          _pauseTimer();
        } else {
          _startTimer();
        }
      } else {
        _isRunning = true;
        _isPaused = false;
        _startTimer();
      }
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _isRunning = false;
      _isPaused = true;
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _seconds = _totalSeconds;
      _currentRound = 1;
      _isResting = false;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _isRunning = true;
    _isPaused = false;
    if (_seconds == 0) {
      _seconds = _totalSeconds;
      _currentRound = 1;
      _isResting = false;
    }

    _playSound('gong.ogg');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          if (_seconds == 12 && !_isResting) {
            _playSound('warning.ogg');
          }
          _seconds--;
        } else {
          if (_isResting) {
            if (_currentRound < _rounds) {
              _currentRound++;
              _seconds = _totalSeconds;
              _isResting = false;
              _playSound('gong.ogg');
            } else {
              _timer!.cancel();
              _isRunning = false;
            }
          } else {
            _seconds = _restSeconds;
            _isResting = true;
            _playSound('gong2.ogg');
          }
        }
      });
    });
  }

  Future<void> _playSound(String sound) async {
    await _audioPlayer.play(AssetSource(sound));
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _seconds ~/ 60;
    int seconds = _seconds % 60;
    double progress =
        _isResting ? _seconds / _restSeconds : _seconds / _totalSeconds;

    Color firstColor;
    Color secondColor;

    if (_isRunning) {
      if (_isResting) {
        firstColor = Colors.yellow.shade400;
        secondColor = Colors.yellow.shade300;
      } else {
        firstColor = Colors.green.shade400;
        secondColor = Colors.green.shade300;
      }
    } else {
      firstColor = const Color.fromARGB(255, 79, 177, 226);
      secondColor = const Color.fromARGB(255, 80, 110, 126);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Round $_currentRound of $_rounds',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 60,
            shadows: [
              const Shadow(
                offset: Offset(-4.0, 2.0),
                blurRadius: 4.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [firstColor, secondColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double size = constraints.biggest.shortestSide * 0.7;
            size = size < 300 ? 300 : size;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: _isResting ? Colors.yellow : Colors.green[900],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: size,
                        height: size,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 25,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isResting
                                ? Colors.yellow.shade800
                                : Colors.greenAccent,
                          ),
                          backgroundColor: Colors.blueGrey[700],
                        ),
                      ),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: size / 2.7,
                          color: _isResting
                              ? Colors.yellow[800]
                              : Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _startPauseTimer,
              child: Icon(
                _isRunning && !_isPaused ? Icons.pause : Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 50),
            if (_isRunning || _isPaused)
              FloatingActionButton(
                onPressed: _stopTimer,
                child: const Icon(Icons.stop),
              ),
            const SizedBox(width: 50),
            FloatingActionButton(
              onPressed: () {
                _showSettingsDialog(context);
              },
              child: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController roundTimeController =
            TextEditingController(text: (_totalSeconds ~/ 60).toString());
        TextEditingController roundsController =
            TextEditingController(text: _rounds.toString());
        TextEditingController restTimeController =
            TextEditingController(text: _restSeconds.toString());

        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: roundTimeController,
                decoration:
                    const InputDecoration(labelText: 'Round Time (minutes)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: roundsController,
                decoration:
                    const InputDecoration(labelText: 'Number of Rounds'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: restTimeController,
                decoration:
                    const InputDecoration(labelText: 'Rest Time (seconds)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  int newTotalSeconds =
                      int.tryParse(roundTimeController.text) != null
                          ? int.parse(roundTimeController.text) * 60
                          : _totalSeconds;
                  int newRounds = int.tryParse(roundsController.text) != null
                      ? int.parse(roundsController.text)
                      : _rounds;
                  int newRestSeconds =
                      int.tryParse(restTimeController.text) != null
                          ? int.parse(restTimeController.text)
                          : _restSeconds;

                  _totalSeconds = newTotalSeconds;
                  _rounds = newRounds;
                  _restSeconds = newRestSeconds;
                  _seconds = _totalSeconds;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
