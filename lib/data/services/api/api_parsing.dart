/// Shared response-shape helpers for the API service implementations.
///
/// The backend's list endpoints return bare JSON arrays today, but tolerate a
/// DRF paginated `{"results": [...]}` envelope too so turning on pagination
/// later doesn't break every screen at once.
List<Map<String, dynamic>> asList(dynamic data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  if (data is Map<String, dynamic> && data['results'] is List) {
    return (data['results'] as List).whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

Map<String, dynamic> asMap(dynamic data) =>
    data is Map<String, dynamic> ? data : const {};
