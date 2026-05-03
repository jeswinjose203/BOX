import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static String? _token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static bool get isLoggedIn => _token != null;

  static Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw Exception(body['detail'] ?? 'Request failed');
  }

  static Future<List<dynamic>> _handleListResponse(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    final body = jsonDecode(res.body);
    throw Exception(body['detail'] ?? 'Request failed');
  }

  // Auth
  static Future<Map<String, dynamic>> signup(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _jsonHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
    );
    final data = await _handleResponse(res);
    await _saveToken(data['access_token']);
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  // Movies
  static Future<Map<String, dynamic>> createMovie(String title, String releaseDate) async {
    final res = await http.post(
      Uri.parse('$baseUrl/movies/'),
      headers: _authHeaders,
      body: jsonEncode({'title': title, 'release_date': releaseDate}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getMovies() async {
    final res = await http.get(Uri.parse('$baseUrl/movies/'));
    return _handleListResponse(res);
  }

  // Contests
  static Future<Map<String, dynamic>> createContest(int movieId, double entryFee, String type, String deadline) async {
    final res = await http.post(
      Uri.parse('$baseUrl/contests/'),
      headers: _authHeaders,
      body: jsonEncode({
        'movie_id': movieId,
        'entry_fee': entryFee,
        'type': type,
        'deadline': deadline,
      }),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getContests() async {
    final res = await http.get(Uri.parse('$baseUrl/contests/'));
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> getContest(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/contests/$id'));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> joinContest(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/contests/$id/join'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  // Predictions
  static Future<Map<String, dynamic>> createPrediction(int contestId, double predictedValue) async {
    final res = await http.post(
      Uri.parse('$baseUrl/predictions/'),
      headers: _authHeaders,
      body: jsonEncode({'contest_id': contestId, 'predicted_value': predictedValue}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getContestPredictions(int contestId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/predictions/contest/$contestId'),
      headers: _authHeaders,
    );
    return _handleListResponse(res);
  }

  // Scoring
  static Future<Map<String, dynamic>> runScoring(int contestId, double actualValue) async {
    final res = await http.post(
      Uri.parse('$baseUrl/scoring/run'),
      headers: _authHeaders,
      body: jsonEncode({'contest_id': contestId, 'actual_value': actualValue}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getLeaderboard(int contestId) async {
    final res = await http.get(Uri.parse('$baseUrl/scoring/leaderboard/$contestId'));
    return _handleListResponse(res);
  }

  // Wallet
  static Future<Map<String, dynamic>> getBalance() async {
    final res = await http.get(
      Uri.parse('$baseUrl/wallet/balance'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  // Deposits
  static Future<Map<String, dynamic>> requestDeposit(double amount, String utr) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposits/request'),
      headers: _authHeaders,
      body: jsonEncode({'amount': amount, 'utr': utr}),
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getMyDeposits() async {
    final res = await http.get(
      Uri.parse('$baseUrl/deposits/mine'),
      headers: _authHeaders,
    );
    return _handleListResponse(res);
  }

  static Future<List<dynamic>> getAllDeposits() async {
    final res = await http.get(
      Uri.parse('$baseUrl/deposits/'),
      headers: _authHeaders,
    );
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> approveDeposit(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposits/approve/$id'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> rejectDeposit(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposits/reject/$id'),
      headers: _authHeaders,
    );
    return _handleResponse(res);
  }
}
