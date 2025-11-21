import 'package:maxi_framework/maxi_framework.dart';

class TableResult extends Iterable<Map<String, dynamic>> {
  final List<String> columnsName;

  final List<Map<String, dynamic>> _values;

  @override
  int get length => _values.length;

  @override
  bool get isEmpty => _values.isEmpty;

  @override
  bool get isNotEmpty => _values.isNotEmpty;

  //TableResult._({required this.columnsName, required List<Map<String, dynamic>> values}) : _values = values;

  TableResult.empty() : columnsName = [], _values = [];
  TableResult.withColumns({required this.columnsName}) : _values = [];
  TableResult.withMap({required Map<String, dynamic> values}) : columnsName = values.keys.toList(), _values = [values];

  static Result<TableResult> withColumnsAndValues({required List<String> columnsName, required List<Map<String, dynamic>> values}) {
    final newTable = TableResult.withColumns(columnsName: columnsName);

    for (final row in values) {
      final wasAdded = newTable.addRow(row);
      if (wasAdded.itsFailure) return wasAdded.cast();
    }

    return newTable.asResultValue();
  }

  @override
  Iterator<Map<String, dynamic>> get iterator => _values.iterator;

  Result<Map<String, dynamic>> getRow(int index) {
    if (index < 0 || index >= _values.length) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain an element positioned at %1', textParts: [index]),
      );
    }
    return _values[index].asResultValue();
  }

  int? getColumnPositionByName({required String columnName, bool caseSensitivity = true}) {
    return columnsName.selectPosition((x) => columnName == x || (!caseSensitivity && columnName.toLowerCase() == x.toLowerCase()));
  }

  Result<List<dynamic>> getColumnByName({required String columnName, bool caseSensitivity = true}) {
    final position = getColumnPositionByName(columnName: columnName, caseSensitivity: caseSensitivity);
    if (position == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain the column %1', textParts: [columnName]),
      );
    }

    return _values.map((row) => row[columnName]).toList().asResultValue();
  }

  Result<int> addRow(Map<String, dynamic> row) {
    for (final column in columnsName) {
      if (!row.containsKey(column)) {
        return NegativeResult.controller(
          code: ErrorCode.nonExistent,
          message: FlexibleOration(message: 'The row does not contain the column %1', textParts: [column]),
        );
      }
    }

    _values.add(row);
    return (_values.length - 1).asResultValue();
  }

  Result getValueByPosition({required int positionColumn, required int positionValue}) {
    if (positionValue < 0 || positionValue >= _values.length) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain an element positioned at %1', textParts: [positionValue]),
      );
    }

    if (positionColumn < 0 || positionColumn >= columnsName.length) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain a column positioned at %1', textParts: [positionColumn]),
      );
    }

    final columnName = columnsName[positionColumn];
    final row = _values[positionValue];
    return row[columnName].asResultValue();
  }

  Result getValueByName({required String columnName, required int positionValue, bool caseSensitivity = true}) {
    final positionColumn = getColumnPositionByName(columnName: columnName, caseSensitivity: caseSensitivity);
    if (positionColumn == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain the column %1', textParts: [columnName]),
      );
    }

    return getValueByPosition(positionColumn: positionColumn, positionValue: positionValue);
  }

  void clean() {
    _values.clear();
  }

  void removeRow({required int position}) {
    if (position < 0 || position >= length) {
      return;
    }

    _values.removeAt(position);
  }

  void removeColumn({required String columnName, bool caseSensitivity = true}) {
    final position = getColumnPositionByName(columnName: columnName, caseSensitivity: caseSensitivity);
    if (position == null) {
      return;
    }

    columnsName.removeAt(position);
    for (final row in _values) {
      row.remove(columnName);
    }
  }

  Result<void> changeRow({required int position, required Map<String, dynamic> newValues, bool caseSensitivity = true, bool ignoreNonExistentColumns = true}) {
    if (position < 0 || position >= length) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The table does not contain an element positioned at %1', textParts: [position]),
      );
    }

    final row = _values[position];
    for (final column in columnsName) {
      final key = caseSensitivity ? column : newValues.keys.firstWhere((k) => k.toLowerCase() == column.toLowerCase(), orElse: () => '');
      if (key.isNotEmpty && newValues.containsKey(key)) {
        row[column] = newValues[key];
      } else if (!ignoreNonExistentColumns) {
        return NegativeResult.controller(
          code: ErrorCode.nonExistent,
          message: FlexibleOration(message: 'The new values do not contain the column %1', textParts: [column]),
        );
      }
    }

    return voidResult;
  }
}
