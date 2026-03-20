import 'dart:typed_data';

extension ListIntExtensions on List<int> {
  ByteData toByteData() => ByteData.sublistView(Uint8List.fromList(this));

  int readUint8(int offset) => this[offset] & 0xFF;

  int readInt16(int offset, [Endian endian = Endian.little]) => toByteData().getInt16(offset, endian);

  int readUint16(int offset, [Endian endian = Endian.little]) => toByteData().getUint16(offset, endian);

  int readInt32(int offset, [Endian endian = Endian.little]) => toByteData().getInt32(offset, endian);

  int readUint32(int offset, [Endian endian = Endian.little]) => toByteData().getUint32(offset, endian);

  int readInt64(int offset, [Endian endian = Endian.little]) => toByteData().getInt64(offset, endian);

  int readUint64(int offset, [Endian endian = Endian.little]) => toByteData().getUint64(offset, endian);

  double readFloat32(int offset, [Endian endian = Endian.little]) => toByteData().getFloat32(offset, endian);

  double readFloat64(int offset, [Endian endian = Endian.little]) => toByteData().getFloat64(offset, endian);

  /// Lee [length] bytes desde [offset] como sub-lista.
  List<int> readBytes(int offset, int length) => sublist(offset, offset + length);
}
