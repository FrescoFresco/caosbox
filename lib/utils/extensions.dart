import '../models/enums.dart';

extension DateFmt on DateTime {
  String _two(int n) => n.toString().padLeft(2, '0');
  String get f => '${_two(day)}/${_two(month)}/$year ${_two(hour)}:${_two(minute)}';
}

extension StatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal    => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived  => 'Archivado 📁',
      };
}
