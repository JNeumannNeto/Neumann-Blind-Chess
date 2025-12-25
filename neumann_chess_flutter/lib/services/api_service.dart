import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/game.dart';

class ApiService {
  // ✅ URL do servidor rodando na AWS
  static const String baseUrl = 'http://3.137.152.178:3000/api';

  String? _token;

  // Helper para decodificar com UTF-8
  dynamic _decodeUtf8(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Auth Methods
  Future<User> register(String username, String email, String password) async {
    try {
      final response = await http.post(
  Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
  body: utf8.encode(jsonEncode({
 'username': username,
    'email': email,
          'password': password,
   })),
      );

      if (response.statusCode == 201) {
    final data = _decodeUtf8(response);
        _token = data['token'];
   await _saveToken(_token!);
     // Os dados do usuário vêm direto no data, não em data['user']
  return User.fromJson(data);  // ✅ Removido ['user']
      } else {
        final error = _decodeUtf8(response);
        throw Exception(error['message'] ?? 'Erro ao registrar');
      }
    } catch (e) {
      print('Erro no registro: $e');
      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    try {
      print('Tentando login para: $email');
      final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
 body: utf8.encode(jsonEncode({
     'email': email,
          'password': password,
    })),
      );

  print('Status do login: ${response.statusCode}');
      print('Resposta: ${utf8.decode(response.bodyBytes)}');

 if (response.statusCode == 200) {
  final data = _decodeUtf8(response);
 _token = data['token'];
        await _saveToken(_token!);
   print('Login bem-sucedido! Token salvo.');
 // Os dados do usuário vêm direto no data, não em data['user']
        return User.fromJson(data);  // ✅ Removido ['user']
      } else {
   final error = _decodeUtf8(response);
        print('Erro no login: ${error['message']}');
  throw Exception(error['message'] ?? 'Erro ao fazer login');
      }
  } catch (e) {
      print('Excecao no login: $e');
      rethrow;
    }
  }

  Future<User> getMe() async {
    await _loadToken();
    try {
      final response = await http.get(
Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(),
  );

      if (response.statusCode == 200) {
   return User.fromJson(_decodeUtf8(response));
      } else {
      throw Exception('Erro ao obter usuario');
    }
    } catch (e) {
      print('Erro ao obter usuario: $e');
      rethrow;
}
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
}

  // Game Methods
  Future<Game> createGame(String? opponentId, String color) async {
    await _loadToken();
    
    final body = {
   'opponentId': opponentId,
  'myColor': color,  // ✅ CORRIGIDO: Usar myColor ao invés de color
    };
    
    print('DEBUG API createGame: body=$body');
    print('DEBUG API createGame: URL=$baseUrl/games');
    print('DEBUG API createGame: headers=${_getHeaders()}');
    print('DEBUG API createGame: JSON=${jsonEncode(body)}');
  
   final response = await http.post(
  Uri.parse('$baseUrl/games'),
      headers: _getHeaders(),
      body: utf8.encode(jsonEncode(body)),
    );

    print('DEBUG API createGame: statusCode=${response.statusCode}');
    print('DEBUG API createGame: response=${utf8.decode(response.bodyBytes)}');

  if (response.statusCode == 201) {
      return Game.fromJson(_decodeUtf8(response));
    } else {
   final error = _decodeUtf8(response);
  print('DEBUG API createGame ERRO: $error');
    throw Exception(error['message'] ?? 'Erro ao criar jogo');
    }
  }

  Future<Game> acceptGame(String gameId) async {
 await _loadToken();
    final response = await http.post(
    Uri.parse('$baseUrl/games/$gameId/accept'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Game.fromJson(_decodeUtf8(response));
    } else {
  final error = _decodeUtf8(response);
      throw Exception(error['message'] ?? 'Erro ao aceitar jogo');
    }
  }

  Future<void> declineGame(String gameId) async {
    await _loadToken();
    final response = await http.delete(  // ✅ CORRIGIDO: DELETE ao invés de POST
  Uri.parse('$baseUrl/games/$gameId'),  // ✅ CORRIGIDO: Sem /decline
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      final error = _decodeUtf8(response);
      throw Exception(error['message'] ?? 'Erro ao recusar jogo');
    }
  }

  Future<Game> getGame(String gameId) async {
    await _loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Game.fromJson(_decodeUtf8(response));
    } else {
      throw Exception('Erro ao obter jogo');
    }
  }

  Future<Map<String, dynamic>> getPendingGames() async {
    await _loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/games/pending'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _decodeUtf8(response);
 } else {
  throw Exception('Erro ao obter jogos pendentes');
  }
  }

  Future<List<Game>> getUserGames(String userId, {int limit = 5}) async {
    await _loadToken();
    final response = await http.get(
  Uri.parse('$baseUrl/games/user/$userId?limit=$limit'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
   final data = _decodeUtf8(response);
      return (data['games'] as List).map((g) => Game.fromJson(g)).toList();
    } else {
      throw Exception('Erro ao obter jogos do usuario');
    }
  }

  Future<Game> makeMove(String gameId, String from, String to, {String? promotion, Map<String, dynamic>? moveData}) async {
    await _loadToken();
    
    // Usar moveData se fornecido, caso contrário usar formato antigo
  final bodyData = moveData ?? {
      'from': from,
 'to': to,
  if (promotion != null) 'promotion': promotion,
    };
    
 print('DEBUG API makeMove: gameId=$gameId, bodyData=$bodyData');
    print('DEBUG API makeMove: URL=$baseUrl/games/$gameId/move');
print('DEBUG API makeMove: headers=${_getHeaders()}');
    print('DEBUG API makeMove: body=${jsonEncode(bodyData)}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/move'),
      headers: _getHeaders(),
 body: utf8.encode(jsonEncode(bodyData)),
    );

    print('DEBUG API makeMove: response.statusCode=${response.statusCode}');
 print('DEBUG API makeMove: response.body=${utf8.decode(response.bodyBytes)}');

    if (response.statusCode == 200) {
      return Game.fromJson(_decodeUtf8(response));
    } else {
      final error = _decodeUtf8(response);
      print('DEBUG API makeMove ERRO: ${error}');
      throw Exception(error['message'] ?? 'Erro ao fazer movimento');
  }
  }

  // Desistir de um jogo
  Future<void> resignGame(String gameId) async {
    await _loadToken();  // ✅ CORRIGIDO: usar _loadToken() ao invés de _getToken()
    
    final response = await http.put(
      Uri.parse('$baseUrl/games/$gameId/end'),
      headers: _getHeaders(),  // ✅ CORRIGIDO: usar _getHeaders() que já inclui o token
      body: utf8.encode(jsonEncode({
'status': 'resigned',
      })),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao desistir do jogo');
    }
  }

  // ✅ NOVO: Finalizar jogo (xeque-mate, empate, afogamento)
  Future<void> endGame(String gameId, String status, {String? winnerId, String? result}) async {
    await _loadToken();
    
    final body = <String, dynamic>{
      'status': status,
    };
    
    if (winnerId != null) {
 body['winnerId'] = winnerId;
    }
    
    if (result != null) {
      body['result'] = result;
    }
    
    print('DEBUG: endGame chamado - gameId=$gameId, status=$status, winnerId=$winnerId, result=$result');
  print('DEBUG: endGame body=$body');

    final response = await http.put(
      Uri.parse('$baseUrl/games/$gameId/end'),
      headers: _getHeaders(),
      body: utf8.encode(jsonEncode(body)),
    );

    print('DEBUG: endGame response.statusCode=${response.statusCode}');
    print('DEBUG: endGame response.body=${utf8.decode(response.bodyBytes)}');

 if (response.statusCode != 200) {
      print('DEBUG: Erro ao finalizar jogo - Status: ${response.statusCode}');
      print('DEBUG: Response: ${utf8.decode(response.bodyBytes)}');
      throw Exception('Falha ao finalizar jogo');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    await _loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=$query'),
 headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return (_decodeUtf8(response) as List)
          .map((u) => User.fromJson(u))
          .toList();
    } else {
      throw Exception('Erro ao buscar usuarios');
  }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _loadToken() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    }
  }

  Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }
}
