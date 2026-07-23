// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// A reactive token provider using StateProvider.
/// Holds the current auth token, null if logged out.
final tokenProvider = StateProvider<String?>((ref) => null);
