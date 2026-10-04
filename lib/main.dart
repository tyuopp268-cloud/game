import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const TreeGameApp());
}

class TreeGameApp extends StatelessWidget {
  const TreeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tree Game',
      theme: ThemeData.dark(),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  double playerX = 150;
  double treeX = 330;

  int direction = 1;
  int treeHp = 100;

  bool movingLeft = false;
  bool movingRight = false;
  bool attacking = false;

  Timer? gameTimer;

  @override
  void initState() {
    super.initState();

    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        updateGame();
      },
    );
  }

  void updateGame() {
    if (!mounted) return;

    setState(() {
      if (movingLeft) {
        playerX -= 3.5;
        direction = -1;
      }

      if (movingRight) {
        playerX += 3.5;
        direction = 1;
      }

      playerX = playerX.clamp(30, 500);
    });
  }

  void attack() {
    if (attacking) return;

    setState(() {
      attacking = true;
    });

    final distance = (treeX - playerX).abs();

    if (distance <= 150) {
      setState(() {
        treeHp -= 10;

        if (treeHp <= 0) {
          treeHp = 100;
        }
      });
    }

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (!mounted) return;

        setState(() {
          attacking = false;
        });
      },
    );
  }

  void stopMoving() {
    setState(() {
      movingLeft = false;
      movingRight = false;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final actualTreeX = width * 0.72;

            treeX = actualTreeX;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GamePainter(
                      playerX: playerX,
                      treeX: treeX,
                      direction: direction,
                      attacking: attacking,
                      treeHp: treeHp,
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  bottom: 30,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            movingLeft = true;
                            movingRight = false;
                          });
                        },
                        onTapUp: (_) {
                          stopMoving();
                        },
                        onTapCancel: () {
                          stopMoving();
                        },
                        child: GameButton(
                          icon: Icons.arrow_back,
                        ),
                      ),

                      const SizedBox(width: 15),

                      GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            movingRight = true;
                            movingLeft = false;
                          });
                        },
                        onTapUp: (_) {
                          stopMoving();
                        },
                        onTapCancel: () {
                          stopMoving();
                        },
                        child: GameButton(
                          icon: Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 25,
                  bottom: 25,
                  child: GestureDetector(
                    onTap: attack,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'ตี',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ต้นไม้ HP: $treeHp',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  final IconData icon;

  const GameButton({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 38,
        color: Colors.white,
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final double playerX;
  final double treeX;
  final int direction;
  final bool attacking;
  final int treeHp;

  GamePainter({
    required this.playerX,
    required this.treeX,
    required this.direction,
    required this.attacking,
    required this.treeHp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.72;

    final skyPaint = Paint()
      ..color = const Color(0xFF87CEEB);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        groundY,
      ),
      skyPaint,
    );

    final groundPaint = Paint()
      ..color = const Color(0xFF4CAF50);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        groundY,
        size.width,
        size.height - groundY,
      ),
      groundPaint,
    );

    drawTree(
      canvas,
      treeX,
      groundY,
    );

    drawPlayer(
      canvas,
      playerX,
      groundY,
    );
  }

  void drawTree(
    Canvas canvas,
    double x,
    double groundY,
  ) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF795548);

    canvas.drawRect(
      Rect.fromLTWH(
        x - 20,
        groundY - 150,
        40,
        150,
      ),
      trunkPaint,
    );

    final leafPaint = Paint()
      ..color = const Color(0xFF2E7D32);

    canvas.drawCircle(
      Offset(x, groundY - 180),
      65,
      leafPaint,
    );

    canvas.drawCircle(
      Offset(x - 45, groundY - 145),
      48,
      leafPaint,
    );

    canvas.drawCircle(
      Offset(x + 45, groundY - 145),
      48,
      leafPaint,
    );

    final hpBack = Paint()
      ..color = Colors.red;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - 50,
          groundY - 245,
          100,
          12,
        ),
        const Radius.circular(6),
      ),
      hpBack,
    );

    final hp = Paint()
      ..color = Colors.green;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - 50,
          groundY - 245,
          treeHp.toDouble(),
          12,
        ),
        const Radius.circular(6),
      ),
      hp,
    );
  }

  void drawPlayer(
    Canvas canvas,
    double x,
    double groundY,
  ) {
    final bodyY = groundY - 105;

    final skin = Paint()
      ..color = const Color(0xFFFFCC99);

    final shirt = Paint()
      ..color = Colors.blue;

    final pants = Paint()
      ..color = Colors.black;

    final headX = x;
    final headY = bodyY - 45;

    canvas.drawCircle(
      Offset(headX, headY),
      25,
      skin,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, bodyY),
        width: 45,
        height: 65,
      ),
      shirt,
    );

    final eyeX = x + (direction * 9);

    canvas.drawCircle(
      Offset(eyeX, headY - 4),
      4,
      Paint()..color = Colors.black,
    );

    final armPaint = Paint()
      ..color = const Color(0xFFFFCC99)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    if (attacking) {
      canvas.drawLine(
        Offset(x, bodyY - 20),
        Offset(
          x + direction * 60,
          bodyY - 55,
        ),
        armPaint,
      );
    } else {
      canvas.drawLine(
        Offset(x - 20, bodyY - 20),
        Offset(x - 42, bodyY + 15),
        armPaint,
      );

      canvas.drawLine(
        Offset(x + 20, bodyY - 20),
        Offset(x + 42, bodyY + 15),
        armPaint,
      );
    }

    final legPaint = Paint()
      ..color = pants.color
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x - 10, bodyY + 32),
      Offset(x - 18, groundY),
      legPaint,
    );

    canvas.drawLine(
      Offset(x + 10, bodyY + 32),
      Offset(x + 18, groundY),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}
