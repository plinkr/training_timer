import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
  int _prepSeconds = 10;
  int _runningPrepSeconds = 10;
  bool _isResting = false;
  bool _isPreparing = false;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _prepCompleted = false;
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
        if (!_prepCompleted) {
          _startPreparation();
        } else {
          _startTimer();
        }
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
      _runningPrepSeconds = _prepSeconds;
      _isResting = false;
      _isPreparing = false;
      _prepCompleted = false;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _startPreparation() {
    setState(() {
      _isPreparing = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_runningPrepSeconds > 0) {
          _runningPrepSeconds--;
        } else {
          _playSound('gong.ogg');
          _isPreparing = false;
          _prepCompleted = true;
          _startTimer();
          timer.cancel();
        }
      });
    });
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _isRunning = true;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          if (_seconds == 11) {
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
              _resetState();
            }
          } else {
            if (_currentRound < _rounds) {
              _seconds = _restSeconds;
              _isResting = true;
              _playSound('gong2.ogg');
            } else {
              _timer!.cancel();
              _resetState();
            }
          }
        }
      });
    });
  }

  void _resetState() {
    setState(() {
      _seconds = _totalSeconds;
      _currentRound = 1;
      _runningPrepSeconds = _prepSeconds;
      _isResting = false;
      _isPreparing = false;
      _prepCompleted = false;
      _isRunning = false;
      _isPaused = false;
    });
  }

  Future<void> _playSound(String sound) async {
    await _audioPlayer.play(AssetSource(sound));
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _seconds ~/ 60;
    int seconds = _seconds % 60;
    double progress = _isPreparing
        ? _runningPrepSeconds / _prepSeconds
        : _isResting
            ? _seconds / _restSeconds
            : _seconds / _totalSeconds;

    Color firstColor;
    Color secondColor;

    if (_isRunning) {
      if (_isPreparing) {
        firstColor = Colors.lightGreen;
        secondColor = Colors.greenAccent;
      } else if (_isResting) {
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
          _isPreparing ? 'Get Ready' : 'Round $_currentRound/$_rounds',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 58,
            shadows: [
              const Shadow(
                offset: Offset(-4.0, 2.0),
                blurRadius: 4.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
        toolbarHeight: kToolbarHeight + 15,
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
                          color: _isResting
                              ? Colors.yellow
                              : _isPreparing
                                  ? Colors.teal[900]
                                  : Colors.green[900],
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
                                : _isPreparing
                                    ? Colors.teal.shade400
                                    : Colors.greenAccent,
                          ),
                          backgroundColor: Colors.blueGrey[700],
                        ),
                      ),
                      Text(
                        _isPreparing
                            ? '$_runningPrepSeconds'
                            : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: size / 2.7,
                          color: _isResting
                              ? Colors.yellow[800]
                              : _isPreparing
                                  ? Colors.teal[400]
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
        TextEditingController prepTimeController =
            TextEditingController(text: _prepSeconds.toString());

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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: roundsController,
                decoration:
                    const InputDecoration(labelText: 'Number of Rounds'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: restTimeController,
                decoration:
                    const InputDecoration(labelText: 'Rest Time (seconds)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                controller: prepTimeController,
                decoration: const InputDecoration(
                    labelText: 'Preparation Time (seconds)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  int newTotalMinutes =
                      int.tryParse(roundTimeController.text) ??
                          _totalSeconds ~/ 60;
                  int newRounds =
                      int.tryParse(roundsController.text) ?? _rounds;
                  int newRestSeconds =
                      int.tryParse(restTimeController.text) ?? _restSeconds;
                  int newPrepSeconds =
                      int.tryParse(prepTimeController.text) ?? _prepSeconds;

                  if (newTotalMinutes < 1) {
                    newTotalMinutes = 1;
                  } else if (newTotalMinutes > 60) {
                    newTotalMinutes = 60;
                  }

                  if (newRounds < 1) {
                    newRounds = 1;
                  } else if (newRounds > 99) {
                    newRounds = 99;
                  }

                  if (newRestSeconds < 5) {
                    newRestSeconds = 5;
                  } else if (newRestSeconds > 3600) {
                    newRestSeconds = 3600;
                  }

                  if (newPrepSeconds < 5) {
                    newPrepSeconds = 5;
                  } else if (newPrepSeconds > 60) {
                    newPrepSeconds = 60;
                  }

                  _totalSeconds = newTotalMinutes * 60;
                  _rounds = newRounds;
                  _restSeconds = newRestSeconds;
                  _prepSeconds = newPrepSeconds;
                  _runningPrepSeconds = _prepSeconds;
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
