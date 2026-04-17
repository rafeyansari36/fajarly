import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/match_code.dart';

final matchCodeUseCaseProvider = Provider<MatchCodeUseCase>((_) {
  return const MatchCodeUseCase();
});
