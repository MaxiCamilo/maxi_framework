import 'dart:io';
import 'dart:math';

class Color {
  final int r, g, b;
  const Color(this.r, this.g, this.b);
}

class BrailleCanvas {
  late int width;   // = columnas * 2
  late int height;  // = filas * 4
  late List<List<Color?>> _px; // null = punto apagado

  // bit del punto braille según [fila 0..3][col 0..1] dentro de la celda
  static const _dot = [
    [0x01, 0x08],
    [0x02, 0x10],
    [0x04, 0x20],
    [0x40, 0x80], // <- los puntos 7/8 saltan a 0x40/0x80 (rareza del encoding)
  ];

  BrailleCanvas() { resize(); }

  void resize() {
    final cols = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final rows = stdout.hasTerminal ? stdout.terminalLines : 24;
    width = cols * 2;
    height = rows * 4;
    _px = List.generate(height, (_) => List<Color?>.filled(width, null));
  }

  void clear() {
    for (final row in _px) row.fillRange(0, width, null);
  }

  void setPixel(int x, int y, Color c) {
    if (x < 0 || x >= width || y < 0 || y >= height) return; // recorte
    _px[y][x] = c;
  }

  void render() {
    final sb = StringBuffer('\x1b[H'); // cursor al origen (sin limpiar = sin parpadeo)
    for (var cy = 0; cy < height ~/ 4; cy++) {
      for (var cx = 0; cx < width ~/ 2; cx++) {
        var bits = 0, rs = 0, gs = 0, bs = 0, lit = 0;
        for (var row = 0; row < 4; row++) {
          for (var col = 0; col < 2; col++) {
            final p = _px[cy * 4 + row][cx * 2 + col];
            if (p != null) {
              bits |= _dot[row][col];
              rs += p.r; gs += p.g; bs += p.b; lit++;
            }
          }
        }
        if (lit == 0) {
          sb.write(' '); // celda sin nada encendido
        } else {
          // un color por celda = promedio de los puntos prendidos
          sb.write('\x1b[38;2;${rs ~/ lit};${gs ~/ lit};${bs ~/ lit}m');
          sb.writeCharCode(0x2800 + bits);
        }
      }
      sb.write('\x1b[0m\n');
    }
    stdout.write(sb.toString());
  }
}

void main() {
  stdout.write('\x1b[2J\x1b[?25l'); // limpiar + ocultar cursor
  final canvas = BrailleCanvas();
  ProcessSignal.sigwinch.watch().listen((_) => canvas.resize());

  canvas.clear();
  final w = canvas.width, h = canvas.height;

  // onda seno (degradé de color a lo largo de x)
  for (var x = 0; x < w; x++) {
    final y = (h / 2 + (h / 3) * sin(x / w * 4 * pi)).round();
    canvas.setPixel(x, y, Color(80, 255 - x * 200 ~/ w, 255));
  }
  // círculo amarillo encima, para que se note la resolución fina
  final cx = w ~/ 2, cy = h ~/ 2, rad = h ~/ 3;
  for (var a = 0; a < 1440; a++) {
    final t = a * pi / 720;
    canvas.setPixel(cx + (rad * cos(t)).round(), cy + (rad * sin(t)).round(), const Color(255, 220, 0));
  }
  canvas.render();

  stdout.write('\x1b[${stdout.terminalLines};1H'); // bajar el cursor
  stdin.readLineSync(); // esperar Enter
  stdout.write('\x1b[0m\x1b[?25h\n'); // restaurar
}