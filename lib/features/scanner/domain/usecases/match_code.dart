import '../../../alarm/domain/entities/expected_code.dart';
import '../entities/scanned_code.dart';

class MatchCodeUseCase {
  const MatchCodeUseCase();

  bool call({required ScannedCode scanned, required ExpectedCode expected}) {
    final value = scanned.value?.trim();
    if (value == null || value.isEmpty) return false;
    if (scanned.formatName != expected.formatName) return false;
    return value == expected.value.trim();
  }
}
