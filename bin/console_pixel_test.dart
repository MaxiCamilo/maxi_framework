import 'dart:io';
import 'dart:math';

class Color {
  final int r, g, b;
  const Color(this.r, this.g, this.b);
}

class Canvas {
  late int width; // píxeles de ancho = columnas
  late int height; // píxeles de alto  = filas * 2
  late List<List<Color>> _px;
  static const _bg = Color(0, 0, 0);

  Canvas() {
    resize();
  }

  void resize() {
    final cols = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final rows = stdout.hasTerminal ? stdout.terminalLines : 24;
    width = cols;
    height = rows * 2;
    _px = List.generate(height, (_) => List.filled(width, _bg));
  }

  void clear([Color c = _bg]) {
    for (final row in _px) row.fillRange(0, width, c);
  }

  void setPixel(int x, int y, Color c) {
    if (x < 0 || x >= width || y < 0 || y >= height) return; // recorte
    _px[y][x] = c;
  }

  void render() {
    // Un solo write por frame: el cuello de botella es la E/S del terminal.
    final sb = StringBuffer('\x1b[H'); // cursor al origen (sin limpiar = sin parpadeo)
    for (var cy = 0; cy < height ~/ 2; cy++) {
      for (var x = 0; x < width; x++) {
        final top = _px[cy * 2][x];
        final bot = _px[cy * 2 + 1][x];
        sb.write('\x1b[38;2;${top.r};${top.g};${top.b}m'); // fg = píxel de arriba
        sb.write('\x1b[48;2;${bot.r};${bot.g};${bot.b}m'); // bg = píxel de abajo
        sb.write('\u2580'); // ▀
      }
      sb.write('\x1b[0m\n'); // reset de color al final de cada fila
    }
    stdout.write(sb.toString());
  }
}

void main() {
  stdout.write('\x1b[2J\x1b[?25l'); // limpiar pantalla + ocultar cursor
  final canvas = Canvas();
  ProcessSignal.sigwinch.watch().listen((_) => canvas.resize()); // re-medir al redimensionar

  // demo: degradé de fondo + círculo blanco
  canvas.clear();
  for (var y = 0; y < canvas.height; y++) {
    for (var x = 0; x < canvas.width; x++) {
      canvas.setPixel(x, y, Color(x * 255 ~/ canvas.width, y * 255 ~/ canvas.height, 80));
    }
  }
  final cx = canvas.width ~/ 2, cy = canvas.height ~/ 2, rad = canvas.height ~/ 3;
  for (var a = 0; a < 720; a++) {
    final t = a * pi / 360;
    canvas.setPixel(cx + (rad * cos(t)).round(), cy + (rad * sin(t)).round(), const Color(255, 255, 255));
  }
  canvas.render();

  stdout.write('\x1b[${stdout.terminalLines};1H'); // bajar el cursor
  stdin.readLineSync(); // esperar Enter
  stdout.write('\x1b[0m\x1b[?25h\n'); // restaurar color + mostrar cursor
}
