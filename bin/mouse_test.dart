import 'dart:io';

const enable = '\x1b[?1000;1006h'; // clicks + coords SGR
const disable = '\x1b[?1000;1006l';
final mouseRe = RegExp(r'\x1b\[<(\d+);(\d+);(\d+)([Mm])');

void cleanup() {
  stdout.write(disable);
  stdin.echoMode = true;
  stdin.lineMode = true;
  exit(0);
}

void main() {
  stdin.echoMode = false;
  stdin.lineMode = false; // bytes al vuelo (raw)
  stdout.write('\x1b[2J\x1b[H'); // limpiar pantalla
  stdout.write(enable);
  stdout.write('Mové y clickeá. q para salir.\r\n');

  var buf = '';
  stdin.listen((data) {
    buf += String.fromCharCodes(data);
    if (buf.contains('q')) cleanup();

    for (final m in mouseRe.allMatches(buf)) {
      final btn = int.parse(m.group(1)!);
      final x = int.parse(m.group(2)!);
      final y = int.parse(m.group(3)!);
      final press = m.group(4) == 'M';

      final scroll = btn & 64 != 0;
      final motion = btn & 32 != 0;
      final base = btn & 3;

      final String tipo;
      if (scroll) {
        tipo = base == 0 ? 'scroll ↑' : 'scroll ↓';
      } else if (motion) {
        tipo = 'movimiento';
      } else {
        tipo = switch (base) {
          0 => 'click izq',
          1 => 'click medio',
          2 => 'click der',
          _ => 'otro',
        };
      }
      // sobrescribir una línea fija con el evento
      stdout.write('\x1b[10;1H\x1b[K$tipo  col=$x fila=$y  ${press ? "↓" : "↑"}\r');
    }
    buf = ''; // simplificación; en serio guardás el resto incompleto del buffer
  });
}
