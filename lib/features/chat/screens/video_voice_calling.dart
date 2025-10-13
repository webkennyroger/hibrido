import 'package:flutter/material.dart';

class VideoCallingScreen extends StatelessWidget {
  const VideoCallingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: CallBg(
        image: Image.network(
          "https://i.postimg.cc/0Q0n66Ff/call-bg.png",
          fit: BoxFit.cover,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Preview of my camera
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  height: 120,
                  width: 96,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 24),
                        blurRadius: 40,
                        color: Colors.black38,
                      ),
                    ],
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                          "https://i.postimg.cc/0Q0n66Ff/call-bg.png"),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0 * 2, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallOption(
                      icon: const Icon(Icons.volume_down),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(Icons.mic),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(Icons.videocam_off),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                      ),
                      color: const Color(0xFFF03738),
                      press: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CallOption extends StatelessWidget {
  const CallOption({
    super.key,
    required this.icon,
    required this.press,
    this.color = Colors.white10,
  });

  final Icon icon;
  final VoidCallback press;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}

class CallBg extends StatelessWidget {
  const CallBg({
    super.key,
    required this.image,
    required this.child,
  });

  final Widget image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1D1D35),
                Colors.transparent,
                Colors.transparent,
                Color(0xFF1D1D35),
              ],
              stops: [0, 0.2, 0.5, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
