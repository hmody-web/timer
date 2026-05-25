import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const GuessTimeApp());
}

// ─── Theme ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF050F05);
const kNeon = Color(0xFF00FF41);
const kNeonDim = Color(0xFF00CC33);
const kNeonDark = Color(0xFF003311);
const kRed = Color(0xFFFF2244);
const kYellow = Color(0xFFFFE500);
const kGray = Color(0xFF1A2B1A);

// ─── Game State ───────────────────────────────────────────────────────────────
enum GameScreen { menu, howToPlay, settings, countdown, playing, results }
enum GameMode { classic, fast, extreme }

class GameState extends ChangeNotifier {
  GameScreen screen = GameScreen.menu;
  GameMode mode = GameMode.classic;
  int scoreP1 = 0;
  int scoreP2 = 0;
  int round = 1;
  int totalRounds = 5;
  double? tapTimeP1;
  double? tapTimeP2;
  double? hiddenStopTime;
  bool p1Tapped = false;
  bool p2Tapped = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String? winner; // 'p1', 'p2', 'draw'

  double get modeDuration {
    switch (mode) {
      case GameMode.fast:
        return 5.0;
      case GameMode.extreme:
        return 30.0;
      case GameMode.classic:
        return 15.0;
    }
  }

  void setScreen(GameScreen s) {
    screen = s;
    notifyListeners();
  }

  void setMode(GameMode m) {
    mode = m;
    notifyListeners();
  }

  void resetRound() {
    tapTimeP1 = null;
    tapTimeP2 = null;
    hiddenStopTime = null;
    p1Tapped = false;
    p2Tapped = false;
    winner = null;
    notifyListeners();
  }

  void resetAll() {
    scoreP1 = 0;
    scoreP2 = 0;
    round = 1;
    resetRound();
  }

  void recordTap(int player, double time) {
    if (player == 1 && !p1Tapped) {
      p1Tapped = true;
      tapTimeP1 = time;
    } else if (player == 2 && !p2Tapped) {
      p2Tapped = true;
      tapTimeP2 = time;
    }
    notifyListeners();
  }

  void revealResult(double stopTime) {
    hiddenStopTime = stopTime;
    double diff1 = tapTimeP1 != null ? (tapTimeP1! - stopTime).abs() : double.infinity;
    double diff2 = tapTimeP2 != null ? (tapTimeP2! - stopTime).abs() : double.infinity;

    if (diff1 == double.infinity && diff2 == double.infinity) {
      winner = 'draw';
    } else if (diff1 < diff2) {
      winner = 'p1';
      scoreP1++;
    } else if (diff2 < diff1) {
      winner = 'p2';
      scoreP2++;
    } else {
      winner = 'draw';
    }
    notifyListeners();
  }

  void nextRound() {
    round++;
    resetRound();
  }

  bool get gameOver => round > totalRounds;
  String? get overallWinner {
    if (scoreP1 > scoreP2) return 'p1';
    if (scoreP2 > scoreP1) return 'p2';
    return 'draw';
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────
class GuessTimeApp extends StatelessWidget {
  const GuessTimeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUESS TIME',
      debugShowCheckedModeBanner: false,
theme: ThemeData.dark().copyWith(
  scaffoldBackgroundColor: kBg,

  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'APixel',
  ),

  primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(
    fontFamily: 'APixel',
  ),
),
      home: const GameRoot(),
    );
  }
}

class GameRoot extends StatefulWidget {
  const GameRoot({super.key});
  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> {
  final GameState _state = GameState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        switch (_state.screen) {
          case GameScreen.menu:
            return MainMenuScreen(state: _state);
          case GameScreen.howToPlay:
            return HowToPlayScreen(state: _state);
          case GameScreen.settings:
            return SettingsScreen(state: _state);
          case GameScreen.countdown:
            return CountdownScreen(state: _state);
          case GameScreen.playing:
            return GameScreen_(state: _state);
          case GameScreen.results:
            return ResultsScreen(state: _state);
        }
      },
    );
  }
}

// ─── Pixel Font Text ──────────────────────────────────────────────────────────
class PixelText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final bool glow;
  final TextAlign align;

  const PixelText(this.text,
      {super.key,
      this.size = 14,
      this.color = kNeon,
      this.glow = false,
      this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'APixel',
      fontSize: size,
      color: color,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
      shadows: glow
          ? [
              Shadow(color: color, blurRadius: 8),
              Shadow(color: color, blurRadius: 16),
              Shadow(color: color.withAlpha(128), blurRadius: 32),
            ]
          : null,
    );
    return Text(text, style: style, textAlign: align);
  }
}

// ─── Neon Button ──────────────────────────────────────────────────────────────
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double width;
  final Color color;
  final double fontSize;

  const NeonButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.width = 220,
      this.color = kNeon,
      this.fontSize = 16});

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: 48,
          decoration: BoxDecoration(
            color: kBg,
            border: Border.all(color: widget.color, width: 2),
            boxShadow: [
              BoxShadow(color: widget.color.withAlpha(100), blurRadius: 12),
              BoxShadow(color: widget.color.withAlpha(50), blurRadius: 24),
            ],
          ),
          child: Center(
            child: PixelText(widget.label,
                size: widget.fontSize, color: widget.color, glow: true),
          ),
        ),
      ),
    );
  }
}

// ─── Scanline Overlay ─────────────────────────────────────────────────────────
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(30)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Pixel Particles Background ───────────────────────────────────────────────
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _Particle {
  double x, y, speed, size, opacity;
  _Particle(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        speed = 0.0003 + r.nextDouble() * 0.0005,
        size = 1 + r.nextDouble() * 2,
        opacity = 0.2 + r.nextDouble() * 0.5;
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 60; i++) _particles.add(_Particle(_rng));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ctrl.addListener(() {
      for (var p in _particles) {
        p.y -= p.speed;
        if (p.y < 0) {
          p.y = 1.0;
          p.x = _rng.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = kNeon.withAlpha((p.opacity * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRect(
        Rect.fromLTWH(p.x * size.width, p.y * size.height, p.size, p.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

// ─── Main Menu ────────────────────────────────────────────────────────────────
class MainMenuScreen extends StatefulWidget {
  final GameState state;
  const MainMenuScreen({super.key, required this.state});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ParticleBackground(),
          const ScanlineOverlay(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Column(
                    children: [
                      Text(
                        'GUESS',
                        style: TextStyle(
                          fontFamily: 'APixel',
                          fontSize: size.width * 0.18,
                          fontWeight: FontWeight.bold,
                          color: kNeon,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                                color: kNeon
                                    .withAlpha((_glowAnim.value * 200).round()),
                                blurRadius: 30 * _glowAnim.value),
                            Shadow(
                                color: kNeon
                                    .withAlpha((_glowAnim.value * 150).round()),
                                blurRadius: 60 * _glowAnim.value),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'TIME',
                        style: TextStyle(
                          fontFamily: 'APixel',
                          fontSize: size.width * 0.22,
                          fontWeight: FontWeight.bold,
                          color: kNeon,
                          letterSpacing: 10,
                          shadows: [
                            Shadow(
                                color: kNeon
                                    .withAlpha((_glowAnim.value * 200).round()),
                                blurRadius: 30 * _glowAnim.value),
                            Shadow(
                                color: kNeon
                                    .withAlpha((_glowAnim.value * 150).round()),
                                blurRadius: 60 * _glowAnim.value),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                PixelText('REACTION TIMING GAME',
                    size: 11, color: kNeonDim, glow: false),
                const SizedBox(height: 40),
                // Mode selector
                _ModeSelector(state: widget.state),
                const SizedBox(height: 32),
                NeonButton(
                  label: '▶  START GAME',
                  onTap: () {
                    widget.state.resetAll();
                    widget.state.setScreen(GameScreen.countdown);
                  },
                  color: kNeon,
                  fontSize: 15,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: '?  HOW TO PLAY',
                  onTap: () => widget.state.setScreen(GameScreen.howToPlay),
                  color: kNeonDim,
                  fontSize: 14,
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: '⚙  SETTINGS',
                  onTap: () => widget.state.setScreen(GameScreen.settings),
                  color: kNeonDim,
                  fontSize: 14,
                ),
                const Spacer(),
                PixelText('2 PLAYERS LOCAL', size: 10, color: kNeonDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final GameState state;
  const _ModeSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeBtn(label: 'FAST\n0-5s', mode: GameMode.fast, state: state),
          const SizedBox(width: 8),
          _ModeBtn(
              label: 'CLASSIC\n0-15s', mode: GameMode.classic, state: state),
          const SizedBox(width: 8),
          _ModeBtn(
              label: 'EXTREME\n0-30s', mode: GameMode.extreme, state: state),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final GameMode mode;
  final GameState state;
  const _ModeBtn(
      {required this.label, required this.mode, required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.mode == mode;
    return GestureDetector(
      onTap: () => state.setMode(mode),
      child: Container(
        width: 90,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? kNeonDark : kBg,
          border: Border.all(
              color: selected ? kNeon : kNeonDark,
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(color: kNeon.withAlpha(80), blurRadius: 12),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'APixel',
              fontSize: 10,
              color: selected ? kNeon : kNeonDim,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: selected
                  ? [Shadow(color: kNeon, blurRadius: 6)]
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─── How To Play ──────────────────────────────────────────────────────────────
class HowToPlayScreen extends StatelessWidget {
  final GameState state;
  const HowToPlayScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ScanlineOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PixelText('HOW TO PLAY', size: 22, glow: true),
                  const SizedBox(height: 4),
                  Container(height: 2, color: kNeon),
                  const SizedBox(height: 24),
                  _Rule('01', 'A hidden timer starts after countdown.'),
                  _Rule('02', 'The timer stops randomly anytime.'),
                  _Rule('03', 'TAP your side BEFORE it stops.'),
                  _Rule('04', 'Closest tap to the stop time wins.'),
                  _Rule('05', '"TOO LATE" if you miss the stop.'),
                  _Rule('06', 'Best of 5 rounds wins the game.'),
                  const SizedBox(height: 28),
                  PixelText('MODES', size: 16, glow: true),
                  const SizedBox(height: 8),
                  _Rule('FAST', '0 → 5 seconds hidden timer'),
                  _Rule('CLASSIC', '0 → 15 seconds hidden timer'),
                  _Rule('EXTREME', '0 → 30 seconds hidden timer'),
                  const Spacer(),
                  Center(
                    child: NeonButton(
                      label: '◀  BACK',
                      onTap: () => state.setScreen(GameScreen.menu),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String num;
  final String text;
  const _Rule(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: PixelText(num, size: 12, color: kNeon, align: TextAlign.left),
          ),
          Expanded(
            child: PixelText(text,
                size: 12, color: kNeonDim, align: TextAlign.left),
          ),
        ],
      ),
    );
  }
}

// ─── Settings ────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  final GameState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ScanlineOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: state,
                builder: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText('SETTINGS', size: 22, glow: true),
                    const SizedBox(height: 4),
                    Container(height: 2, color: kNeon),
                    const SizedBox(height: 32),
                    _ToggleSetting(
                      label: 'SOUND FX',
                      value: state.soundEnabled,
                      onToggle: () {
                        state.soundEnabled = !state.soundEnabled;
                        state.notifyListeners();
                      },
                    ),
                    const SizedBox(height: 20),
                    _ToggleSetting(
                      label: 'VIBRATION',
                      value: state.vibrationEnabled,
                      onToggle: () {
                        state.vibrationEnabled = !state.vibrationEnabled;
                        state.notifyListeners();
                      },
                    ),
                    const SizedBox(height: 32),
                    PixelText('ROUNDS', size: 14, color: kNeonDim),
                    const SizedBox(height: 12),
                    Row(
                      children: [3, 5, 7].map((r) {
                        final sel = state.totalRounds == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              state.totalRounds = r;
                              state.notifyListeners();
                            },
                            child: Container(
                              width: 64,
                              height: 48,
                              decoration: BoxDecoration(
                                color: sel ? kNeonDark : kBg,
                                border: Border.all(
                                    color: sel ? kNeon : kNeonDark, width: 2),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: kNeon.withAlpha(80),
                                            blurRadius: 10)
                                      ]
                                    : null,
                              ),
                              child: Center(
                                  child: PixelText('$r',
                                      size: 18,
                                      color: sel ? kNeon : kNeonDim,
                                      glow: sel)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Center(
                      child: NeonButton(
                        label: '◀  BACK',
                        onTap: () => state.setScreen(GameScreen.menu),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;
  const _ToggleSetting(
      {required this.label, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PixelText(label, size: 14, color: kNeonDim),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 64,
            height: 30,
            decoration: BoxDecoration(
              color: value ? kNeonDark : kBg,
              border: Border.all(color: value ? kNeon : kNeonDark, width: 2),
              boxShadow: value
                  ? [BoxShadow(color: kNeon.withAlpha(80), blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: PixelText(value ? 'ON' : 'OFF',
                  size: 11,
                  color: value ? kNeon : kNeonDark.withAlpha(200),
                  glow: value),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Countdown Screen ─────────────────────────────────────────────────────────
class CountdownScreen extends StatefulWidget {
  final GameState state;
  const CountdownScreen({super.key, required this.state});
  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  int _count = 3;
  bool _showGo = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween(begin: 1.8, end: 0.8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _tick();
  }

  void _tick() {
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_count > 1) {
        setState(() => _count--);
        _ctrl.reset();
        _ctrl.forward();
        _tick();
      } else {
        setState(() {
          _showGo = true;
          _count = 0;
        });
        _ctrl.reset();
        _ctrl.forward();
        Timer(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          widget.state.resetRound();
          widget.state.setScreen(GameScreen.playing);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ParticleBackground(),
          const ScanlineOverlay(),
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: _showGo
                      ? Text('GO!',
                          style: TextStyle(
                            fontFamily: 'APixel',
                            fontSize: size.width * 0.28,
                            fontWeight: FontWeight.bold,
                            color: kNeon,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(color: kNeon, blurRadius: 20),
                              Shadow(color: kNeon.withAlpha(150), blurRadius: 40),
                            ],
                          ))
                      : Text('$_count',
                          style: TextStyle(
                            fontFamily: 'APixel',
                            fontSize: size.width * 0.38,
                            fontWeight: FontWeight.bold,
                            color: kNeon,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(color: kNeon, blurRadius: 20),
                              Shadow(color: kNeon.withAlpha(150), blurRadius: 40),
                            ],
                          )),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: PixelText(
                  'ROUND ${widget.state.round} / ${widget.state.totalRounds}',
                  size: 13,
                  color: kNeonDim),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Game Screen ──────────────────────────────────────────────────────────────
class GameScreen_ extends StatefulWidget {
  final GameState state;
  const GameScreen_({super.key, required this.state});
  @override
  State<GameScreen_> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen_>
    with TickerProviderStateMixin {
  late double _stopTime;
  double _elapsed = 0;
  Timer? _gameTimer;
  bool _stopped = false;

  // Guess state for each player: [seconds, tenths, hundredths]
  // We store the guess as total milliseconds for easy math
  // Each digit spinner: 0-59 for seconds, 0-9 for tenths, 0-9 for hundredths
  final List<int> _guessP1 = [0, 0, 0]; // [sec, tenth, hundredth]
  final List<int> _guessP2 = [0, 0, 0];
  bool _p1Submitted = false;
  bool _p2Submitted = false;

  late AnimationController _blinkCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    final rng = Random();
    _stopTime = 2.0 + rng.nextDouble() * (widget.state.modeDuration - 2.0);

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted) return;
      setState(() {
        _elapsed += 0.016;
        if (_elapsed >= _stopTime && !_stopped) {
          _stopped = true;
          t.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  double _guessToSeconds(List<int> g) {
    return g[0].toDouble() + g[1] * 0.1 + g[2] * 0.01;
  }

  void _submit(int player) {
    if (!_stopped) return;
    HapticFeedback.mediumImpact();
    final guessTime = player == 1
        ? _guessToSeconds(_guessP1)
        : _guessToSeconds(_guessP2);
    widget.state.recordTap(player, guessTime);
    setState(() {
      if (player == 1) _p1Submitted = true;
      else _p2Submitted = true;
    });
    if (_p1Submitted && _p2Submitted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        widget.state.revealResult(_stopTime);
        widget.state.setScreen(GameScreen.results);
      });
    }
  }

  void _changeDigit(List<int> guess, int digitIndex, int delta, int player) {
    if (!_stopped) return;
    if (player == 1 && _p1Submitted) return;
    if (player == 2 && _p2Submitted) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (digitIndex == 0) {
        // seconds 0-59
        guess[0] = (guess[0] + delta).clamp(0, 59);
      } else {
        // tenths and hundredths 0-9
        guess[digitIndex] = (guess[digitIndex] + delta).clamp(0, 9);
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _blinkCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatElapsed(double t) {
    final secs = t.floor().clamp(0, 99);
    final tenths = ((t * 10).floor() % 10);
    final hundredths = ((t * 100).floor() % 10);
    return '${secs.toString().padLeft(2, '0')}:$tenths$hundredths';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ScanlineOverlay(),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar: scores ──────────────────────────────────────
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: kNeonDark, width: 1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ScoreBox('P1', widget.state.scoreP1, kNeon),
                        PixelText(
                            'ROUND ${widget.state.round}/${widget.state.totalRounds}',
                            size: 11,
                            color: kNeonDim),
                        _ScoreBox('P2', widget.state.scoreP2, kYellow),
                      ],
                    ),
                  ),
                ),

                // ── Hidden Timer ──────────────────────────────────────────
                const SizedBox(height: 16),
                _HiddenTimer(
                  elapsed: _elapsed,
                  stopped: _stopped,
                  formatElapsed: _formatElapsed,
                  blinkCtrl: _blinkCtrl,
                  pulseAnim: _pulseAnim,
                ),
                const SizedBox(height: 12),

                // ── "Guess Now" label or "Running..." ────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _stopped
                      ? AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Opacity(
                            opacity: _pulseAnim.value,
                            child: PixelText(
                              '◀ خمن الآن! ▶',
                              size: 16,
                              color: kRed,
                              glow: true,
                            ),
                          ),
                        )
                      : PixelText('• • •', size: 14, color: kNeonDark),
                ),

                const SizedBox(height: 16),

                // ── Divider ───────────────────────────────────────────────
                Container(height: 1, color: kNeonDark),

                // ── Two player guess panels ───────────────────────────────
                Expanded(
                  child: Row(
                    children: [
                      // Player 1
                      Expanded(
                        child: _GuessPanel(
                          player: 1,
                          color: kNeon,
                          guess: _guessP1,
                          active: _stopped && !_p1Submitted,
                          submitted: _p1Submitted,
                          onChangeDigit: (idx, delta) =>
                              _changeDigit(_guessP1, idx, delta, 1),
                          onSubmit: () => _submit(1),
                          size: size,
                        ),
                      ),
                      // Divider
                      Container(
                        width: 2,
                        color: kNeonDark,
                      ),
                      // Player 2
                      Expanded(
                        child: _GuessPanel(
                          player: 2,
                          color: kYellow,
                          guess: _guessP2,
                          active: _stopped && !_p2Submitted,
                          submitted: _p2Submitted,
                          onChangeDigit: (idx, delta) =>
                              _changeDigit(_guessP2, idx, delta, 2),
                          onSubmit: () => _submit(2),
                          size: size,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hidden Timer Widget ──────────────────────────────────────────────────────
class _HiddenTimer extends StatelessWidget {
  final double elapsed;
  final bool stopped;
  final String Function(double) formatElapsed;
  final AnimationController blinkCtrl;
  final Animation<double> pulseAnim;

  const _HiddenTimer({
    required this.elapsed,
    required this.stopped,
    required this.formatElapsed,
    required this.blinkCtrl,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: kNeonDark.withAlpha(60),
          border: Border.all(
            color: stopped ? kRed : kNeonDark,
            width: 2,
          ),
          boxShadow: stopped
              ? [BoxShadow(color: kRed.withAlpha(80), blurRadius: 20)]
              : [BoxShadow(color: kNeon.withAlpha(20), blurRadius: 10)],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: stopped
              // Revealed: show "خمن الآن" label over blurred time
              ? Column(
                  key: const ValueKey('stopped'),
                  children: [
                    PixelText('المؤقت توقف!', size: 10, color: kRed),
                    const SizedBox(height: 4),
                    // Timer hidden — show question marks
                    Text(
                      '??.??',
                      style: TextStyle(
                        fontFamily: 'APixel',
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: kRed,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: kRed, blurRadius: 12),
                          Shadow(color: kRed.withAlpha(150), blurRadius: 24),
                        ],
                      ),
                    ),
                  ],
                )
              // Running: show masked timer
              : AnimatedBuilder(
                  key: const ValueKey('running'),
                  animation: blinkCtrl,
                  builder: (_, __) => Column(
                    children: [
                      PixelText('المؤقت يعمل', size: 10, color: kNeonDim),
                      const SizedBox(height: 4),
                      // Black box covering the digits
                      Container(
                        width: 180,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kBg,
                          border: Border.all(
                            color: kNeon.withAlpha(
                                (blinkCtrl.value * 180 + 40).round()),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kNeon.withAlpha(
                                  (blinkCtrl.value * 60).round()),
                              blurRadius: 12,
                            )
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              if (i == 2) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Text(
                                    ':',
                                    style: TextStyle(
                                      fontFamily: 'APixel',
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: kNeonDark.withAlpha(
                                          (blinkCtrl.value * 200 + 40)
                                              .round()),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                width: 26,
                                height: 36,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: kNeonDark.withAlpha(60),
                                  border: Border.all(
                                    color: kNeonDark,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '█',
                                    style: TextStyle(
                                      fontFamily: 'APixel',
                                      fontSize: 20,
                                      color: kNeonDark.withAlpha(
                                          (blinkCtrl.value * 180 + 40)
                                              .round()),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Guess Panel ──────────────────────────────────────────────────────────────
class _GuessPanel extends StatelessWidget {
  final int player;
  final Color color;
  final List<int> guess;
  final bool active;
  final bool submitted;
  final void Function(int digitIndex, int delta) onChangeDigit;
  final VoidCallback onSubmit;
  final Size size;

  const _GuessPanel({
    required this.player,
    required this.color,
    required this.guess,
    required this.active,
    required this.submitted,
    required this.onChangeDigit,
    required this.onSubmit,
    required this.size,
  });

  String _formatGuess() {
    final sec = guess[0].toString().padLeft(2, '0');
    return '$sec:${guess[1]}${guess[2]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player label
          PixelText('PLAYER $player',
              size: 12, color: submitted ? color : (active ? color : kNeonDark)),
          const SizedBox(height: 8),

          // Submitted state
          if (submitted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                color: color.withAlpha(20),
                boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 16)],
              ),
              child: Column(
                children: [
                  PixelText('تخمينك', size: 9, color: color),
                  const SizedBox(height: 4),
                  PixelText(_formatGuess(), size: 22, color: color, glow: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelText('✓ تم الإرسال', size: 11, color: color, glow: true),
          ]

          // Waiting state (timer hasn't stopped)
          else if (!active) ...[
            const SizedBox(height: 16),
            Text('⏳',
                style: TextStyle(
                  fontSize: 40,
                  color: kNeonDark,
                )),
            const SizedBox(height: 12),
            PixelText('انتظر...', size: 11, color: kNeonDark),
          ]

          // Active guessing state
          else ...[
            // Digit spinners: [seconds(2digit)] : [tenths] [hundredths]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Seconds spinner
                _DigitSpinner(
                  label: 'ثواني',
                  value: guess[0],
                  color: color,
                  active: true,
                  padded: true,
                  onUp: () => onChangeDigit(0, 1),
                  onDown: () => onChangeDigit(0, -1),
                ),
                // Colon separator
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(':',
                      style: TextStyle(
                        fontFamily: 'APixel',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      )),
                ),
                // Tenths spinner
                _DigitSpinner(
                  label: 'عُشر',
                  value: guess[1],
                  color: color,
                  active: true,
                  padded: false,
                  onUp: () => onChangeDigit(1, 1),
                  onDown: () => onChangeDigit(1, -1),
                ),
                // Hundredths spinner
                _DigitSpinner(
                  label: 'مئة',
                  value: guess[2],
                  color: color,
                  active: true,
                  padded: false,
                  onUp: () => onChangeDigit(2, 1),
                  onDown: () => onChangeDigit(2, -1),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Current guess preview
            PixelText(_formatGuess(), size: 13, color: color.withAlpha(180)),

            const SizedBox(height: 12),

            // Submit button
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: double.infinity,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 12)],
                ),
                child: Center(
                  child: PixelText('تأكيد ✓', size: 13, color: color, glow: true),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Digit Spinner ────────────────────────────────────────────────────────────
class _DigitSpinner extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool active;
  final bool padded;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _DigitSpinner({
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.padded,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = padded
        ? value.toString().padLeft(2, '0')
        : value.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        PixelText(label, size: 7, color: color.withAlpha(150)),
        const SizedBox(height: 4),

        // Up arrow
        GestureDetector(
          onTap: active ? onUp : null,
          child: Container(
            width: padded ? 46 : 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? color.withAlpha(30) : Colors.transparent,
              border: Border.all(
                  color: active ? color.withAlpha(120) : kNeonDark, width: 1),
            ),
            child: Center(
              child: Text(
                '▲',
                style: TextStyle(
                  fontSize: 14,
                  color: active ? color : kNeonDark,
                  shadows: active
                      ? [Shadow(color: color, blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 3),

        // Digit display
        Container(
          width: padded ? 46 : 32,
          height: 42,
          decoration: BoxDecoration(
            color: active ? kNeonDark.withAlpha(80) : Colors.transparent,
            border: Border.all(
                color: active ? color : kNeonDark, width: active ? 2 : 1),
            boxShadow: active
                ? [BoxShadow(color: color.withAlpha(60), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              displayValue,
              style: TextStyle(
                fontFamily: 'APixel',
                fontSize: padded ? 22 : 22,
                fontWeight: FontWeight.bold,
                color: active ? color : kNeonDark,
                shadows: active
                    ? [Shadow(color: color, blurRadius: 8)]
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 3),

        // Down arrow
        GestureDetector(
          onTap: active ? onDown : null,
          child: Container(
            width: padded ? 46 : 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? color.withAlpha(30) : Colors.transparent,
              border: Border.all(
                  color: active ? color.withAlpha(120) : kNeonDark, width: 1),
            ),
            child: Center(
              child: Text(
                '▼',
                style: TextStyle(
                  fontSize: 14,
                  color: active ? color : kNeonDark,
                  shadows: active
                      ? [Shadow(color: color, blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBox(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PixelText(label, size: 11, color: kNeonDim),
        PixelText('$score', size: 28, color: color, glow: true),
      ],
    );
  }
}

// ─── Results Screen ───────────────────────────────────────────────────────────
class ResultsScreen extends StatefulWidget {
  final GameState state;
  const ResultsScreen({super.key, required this.state});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _winCtrl;
  late Animation<double> _winAnim;

  @override
  void initState() {
    super.initState();
    _winCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _winAnim = Tween(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _winCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _winCtrl.dispose();
    super.dispose();
  }

  String _winnerText() {
    switch (widget.state.winner) {
      case 'p1':
        return '◀ PLAYER 1 WINS!';
      case 'p2':
        return 'PLAYER 2 WINS! ▶';
      default:
        return '★ DRAW ★';
    }
  }

  Color _winnerColor() {
    switch (widget.state.winner) {
      case 'p1':
        return kNeon;
      case 'p2':
        return kYellow;
      default:
        return kNeonDim;
    }
  }

  bool get _gameOver => widget.state.round > widget.state.totalRounds;

  String _overallWinnerText() {
    switch (widget.state.overallWinner) {
      case 'p1':
        return 'PLAYER 1\nWINS THE MATCH!';
      case 'p2':
        return 'PLAYER 2\nWINS THE MATCH!';
      default:
        return 'MATCH\nDRAW!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const ParticleBackground(),
          const ScanlineOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  PixelText('ROUND ${s.round > s.totalRounds ? s.totalRounds : s.round} RESULT',
                      size: 14, color: kNeonDim),
                  const SizedBox(height: 16),

                  // Winner announcement
                  AnimatedBuilder(
                    animation: _winAnim,
                    builder: (_, __) => Opacity(
                      opacity: _winAnim.value,
                      child: PixelText(_winnerText(),
                          size: 22,
                          color: _winnerColor(),
                          glow: true,
                          align: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stop time reveal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: kNeon, width: 2),
                      color: kNeonDark.withAlpha(80),
                      boxShadow: [
                        BoxShadow(color: kNeon.withAlpha(50), blurRadius: 16)
                      ],
                    ),
                    child: Column(
                      children: [
                        PixelText('HIDDEN TIMER STOPPED AT',
                            size: 11, color: kNeonDim),
                        const SizedBox(height: 6),
                        PixelText(
                          s.hiddenStopTime != null
                              ? '${s.hiddenStopTime!.toStringAsFixed(3)}s'
                              : '--',
                          size: 32,
                          glow: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Player comparison
                  Row(
                    children: [
                      Expanded(
                          child: _PlayerResult(
                        label: 'P1',
                        tapTime: s.tapTimeP1,
                        stopTime: s.hiddenStopTime,
                        isWinner: s.winner == 'p1',
                        color: kNeon,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _PlayerResult(
                        label: 'P2',
                        tapTime: s.tapTimeP2,
                        stopTime: s.hiddenStopTime,
                        isWinner: s.winner == 'p2',
                        color: kYellow,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Score bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PixelText('${s.scoreP1}', size: 28, color: kNeon, glow: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PixelText('VS', size: 14, color: kNeonDim),
                      ),
                      PixelText('${s.scoreP2}',
                          size: 28, color: kYellow, glow: true),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Game over or next round
                  if (_gameOver) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: _winnerColor(), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: _winnerColor().withAlpha(80),
                              blurRadius: 20)
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _winAnim,
                        builder: (_, __) => Opacity(
                          opacity: _winAnim.value,
                          child: PixelText(_overallWinnerText(),
                              size: size.width * 0.055,
                              color: _winnerColor(),
                              glow: true,
                              align: TextAlign.center),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    NeonButton(
                      label: '↺  PLAY AGAIN',
                      onTap: () {
                        s.resetAll();
                        s.setScreen(GameScreen.countdown);
                      },
                      color: kNeon,
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      label: '⌂  MAIN MENU',
                      onTap: () {
                        s.resetAll();
                        s.setScreen(GameScreen.menu);
                      },
                      color: kNeonDim,
                    ),
                  ] else ...[
                    NeonButton(
                      label: '▶  NEXT ROUND',
                      onTap: () {
                        s.nextRound();
                        s.setScreen(GameScreen.countdown);
                      },
                      color: kNeon,
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      label: '⌂  MAIN MENU',
                      onTap: () {
                        s.resetAll();
                        s.setScreen(GameScreen.menu);
                      },
                      color: kNeonDim,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerResult extends StatelessWidget {
  final String label;
  final double? tapTime;
  final double? stopTime;
  final bool isWinner;
  final Color color;

  const _PlayerResult({
    required this.label,
    required this.tapTime,
    required this.stopTime,
    required this.isWinner,
    required this.color,
  });

  String get _diffText {
    if (tapTime == null) return 'TOO LATE';
    if (stopTime == null) return '--';
    final diff = (tapTime! - stopTime!).abs();
    return '±${diff.toStringAsFixed(3)}s';
  }

  bool get _tooLate => tapTime == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? color.withAlpha(20) : kBg,
        border: Border.all(
            color: isWinner ? color : kNeonDark,
            width: isWinner ? 2 : 1),
        boxShadow: isWinner
            ? [BoxShadow(color: color.withAlpha(60), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          PixelText('PLAYER $label', size: 11, color: color),
          const SizedBox(height: 8),
          PixelText(
            tapTime != null
                ? '${tapTime!.toStringAsFixed(3)}s'
                : '---',
            size: 18,
            color: _tooLate ? kRed : color,
            glow: isWinner,
          ),
          const SizedBox(height: 4),
          PixelText(
            _diffText,
            size: 11,
            color: _tooLate ? kRed : kNeonDim,
          ),
          if (isWinner) ...[
            const SizedBox(height: 6),
            PixelText('★ WIN', size: 12, color: color, glow: true),
          ],
          if (_tooLate) ...[
            const SizedBox(height: 6),
            PixelText('TOO LATE', size: 11, color: kRed),
          ],
        ],
      ),
    );
  }
}