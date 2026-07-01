/// Fetches historical telemetry for download (replace URL when API is ready).
class HistoryApiService {
  /// Calls the history API for the given date range.
  ///
  /// Returns file bytes on success. Throws if the request fails.
  Future<List<int>> downloadHistory({
    required DateTime start,
    required DateTime end,
    String? evid,
  }) async {
    // TODO: replace with your real REST endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!end.isAfter(start)) {
      throw ArgumentError('End date must be after start date');
    }

    // Stub response until backend URL is configured.
    final stub =
        'evid,pack,soc,voltage,current,start,end\n'
        '${evid ?? 'EV0001'},1,68,48,0,${start.toIso8601String()},${end.toIso8601String()}\n';

    return stub.codeUnits;
  }
}
