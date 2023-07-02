import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Color boxColor;

  AudioPlayerWidget({required this.audioPath, required this.boxColor});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    loadAudio();
  }

  void loadAudio() async {
    await player.setUrl(widget.audioPath);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.boxColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(children: [
        SizedBox(
          width: 5,
        ),
        StreamBuilder<ProcessingState>(
          stream: player.processingStateStream,
          builder: (context, snapshot) {
            final processingState = snapshot.data ?? ProcessingState.idle;
            return IconButton(
              icon: Icon(
                processingState == ProcessingState.completed
                    ? Icons.replay
                    : (player.playing ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (processingState == ProcessingState.completed) {
                    player.seek(Duration.zero);
                    player.play();
                  } else {
                    player.playing ? player.pause() : player.play();
                  }
                });
              },
            );
          },
        ),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration;
              return Slider(
                onChanged: (value) {
                  player.seek(Duration(seconds: value.toInt()));
                },
                value: position.inSeconds.toDouble(),
                min: 0.0,
                max: duration?.inSeconds.toDouble() ?? 0.0,
                inactiveColor: Colors.grey,
                activeColor: Colors.white,
              );
            },
          ),
        ),
      ]),
    );
  }
}
