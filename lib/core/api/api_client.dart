import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _cachedToken;
  
  static Future<Map<String, String>> _getHeaders() async {
    if (_cachedToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('access_token');
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    };
  }
  
  static Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      print('📡 GET $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      print('📡 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }
  
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      print('📡 POST $baseUrl$endpoint');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      print('📡 Status: ${response.statusCode}');
      print('📡 Resposta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }
  
  // ===== AUTENTICAÇÃO =====
  
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      print('📡 Login - $phone');
      final response = await http.post(
        Uri.parse('$baseUrl/users/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        _cachedToken = data['access'];
        return data;
      }
      throw Exception('Login falhou');
    } catch (e) {
      throw Exception('Erro de conexão');
    }
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _cachedToken = null;
  }
  
  static Future<bool> isLoggedIn() async {
    if (_cachedToken != null) return true;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('access_token');
    return _cachedToken != null;
  }
  
  // ===== MÉTODO getCurrentUser CORRIGIDO (COM ID) =====
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await get('/users/me/');
      if (response != null) {
        print('👤 Usuário carregado: ID ${response['id']} - ${response['full_name']}');
        return response;
      }
      return {
        'id': 0,
        'full_name': 'Motorista',
        'user_type': 'DRIVER'
      };
    } catch (e) {
      print('❌ Erro ao buscar usuário: $e');
      return {
        'id': 0,
        'full_name': 'Motorista',
        'user_type': 'DRIVER'
      };
    }
  }
  
  // ===== MÉTODOS PARA VIAGENS =====
  
  static Future<List<dynamic>> getPendingTripsRaw() async {
    try {
      final response = await get('/trips/pending/');
      if (response is List) return response;
      return [];
    } catch (e) {
      print('Erro: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> acceptTrip(int tripId) async {
    try {
      print('✅ Aceitando viagem #$tripId...');
      final response = await post('/trips/$tripId/accept/', {});
      print('✅ Resposta: $response');
      return response;
    } catch (e) {
      print('❌ Erro detalhado: $e');
      if (e.toString().contains('400')) {
        throw Exception('Não foi possível aceitar. Verifique se você tem um veículo disponível.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> startTrip(int tripId) async {
    try {
      print('🚗 Iniciando viagem #$tripId...');
      final response = await post('/trips/$tripId/start/', {});
      return response;
    } catch (e) {
      print('❌ Erro ao iniciar: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> completeTrip(int tripId) async {
    try {
      print('🏁 Completando viagem #$tripId...');
      final response = await post('/trips/$tripId/complete/', {});
      return response;
    } catch (e) {
      print('❌ Erro ao completar: $e');
      rethrow;
    }
  }

  // ===== BUSCAR DETALHES DO PASSAGEIRO PELO ID =====
  static Future<Map<String, dynamic>?> getPassengerDetails(int passengerId) async {
    try {
      print('🔍 Buscando detalhes do passageiro ID: $passengerId');
      final response = await get('/users/$passengerId/');
      return response;
    } catch (e) {
      print('❌ Erro ao buscar passageiro: $e');
      return null;
    }
  }

  // ===== CONVERTER COORDENADAS EM ENDEREÇO DETALHADO =====
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Usando Nominatim (OpenStreetMap) - gratuito
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'METY Driver App'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          
          // Extrair informações detalhadas
          String bairro = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? '';
          String rua = address['road'] ?? address['pedestrian'] ?? '';
          String cidade = address['city'] ?? address['town'] ?? address['village'] ?? '';
          
          // Construir endereço completo
          if (rua.isNotEmpty && bairro.isNotEmpty) {
            return '$rua, $bairro';
          } else if (rua.isNotEmpty) {
            return rua;
          } else if (bairro.isNotEmpty) {
            return bairro;
          } else if (cidade.isNotEmpty) {
            return cidade;
          }
        }
      }
      return 'Localização atual';
    } catch (e) {
      print('❌ Erro ao buscar endereço: $e');
      return 'Localização atual';
    }
  }

  // ===== BUSCAR APENAS VIAGENS RECENTES (ÚLTIMAS 2 HORAS) =====
  static Future<List<dynamic>> getRecentPendingTrips() async {
    try {
      final response = await get('/trips/pending/');
      if (response is List) {
        // Filtrar viagens das últimas 2 horas
        final now = DateTime.now();
        final duasHorasAtras = now.subtract(const Duration(hours: 2));
        
        final recentes = response.where((trip) {
          if (trip['requested_at'] == null) return false;
          try {
            final data = DateTime.parse(trip['requested_at']);
            return data.isAfter(duasHorasAtras);
          } catch (e) {
            return false;
          }
        }).toList();
        
        print('✅ Viagens recentes: ${recentes.length} (de ${response.length} total)');
        return recentes;
      }
      return [];
    } catch (e) {
      print('❌ Erro: $e');
      return [];
    }
  }

  // ===== MÉTODO getAcceptedTrips CORRIGIDO =====
  static Future<List<dynamic>> getAcceptedTrips() async {
    try {
      print('🚗 Buscando viagens aceitas...');
      
      // Buscar todas as viagens
      final response = await get('/trips/');
      
      // IMPORTANTE: Verificar o tipo da resposta
      List<dynamic> todas = [];
      if (response is List) {
        todas = response;
      } else if (response is Map && response.containsKey('results')) {
        todas = response['results'];
      } else {
        print('⚠️ Formato inesperado: $response');
        return [];
      }
      
      print('📦 Total de viagens: ${todas.length}');
      
      // Buscar ID do motorista
      final user = await getCurrentUser();
      final driverId = user['id'];
      print('👤 Motorista ID: $driverId');
      
      // Filtrar viagens do motorista com status ACCEPTED ou STARTED
      final minhasViagens = todas.where((trip) {
        return trip['driver'] == driverId && 
               (trip['status'] == 'ACCEPTED' || trip['status'] == 'STARTED');
      }).toList();
      
      print('✅ Minhas viagens ativas: ${minhasViagens.length}');
      
      // Mostrar cada viagem encontrada
      for (var trip in minhasViagens) {
        print('   ID: ${trip['id']} | Status: ${trip['status']} | Preço: ${trip['price']}');
      }
      
      return minhasViagens;
    } catch (e) {
      print('❌ Erro: $e');
      return [];
    }
  }

  // ===== BUSCAR VIAGEM ESPECÍFICA POR ID =====
  static Future<Map<String, dynamic>?> getTripById(int tripId) async {
    try {
      return await get('/trips/$tripId/');
    } catch (e) {
      print('❌ Erro ao buscar viagem: $e');
      return null;
    }
  }

  // ===== MÉTODO DE TESTE - VAI MOSTRAR TODAS AS VIAGENS =====
  static Future<List<dynamic>> getAllTrips() async {
    try {
      print('🔍 Buscando TODAS as viagens...');
      final response = await get('/trips/');
      
      // IMPORTANTE: Verificar o tipo da resposta
      if (response is List) {
        print('📦 Total: ${response.length} viagens');
        for (var trip in response) {
          print('   ID: ${trip['id']} | Status: ${trip['status']} | Driver: ${trip['driver']}');
        }
        return response;
      } else if (response is Map && response.containsKey('results')) {
        // Se vier paginado
        final lista = response['results'];
        print('📦 Total (paginado): ${lista.length} viagens');
        return lista;
      }
      
      print('⚠️ Resposta não é lista: $response');
      return [];
    } catch (e) {
      print('❌ Erro: $e');
      return [];
    }
  }

  // ===== MÉTODO DE TESTE MAIS DETALHADO =====
  static Future<void> testarTodasViagensDetalhado() async {
    try {
      print('🔍 ===== TESTE DETALHADO =====');
      
      // 1. Pegar usuário atual
      final user = await get('/users/me/');
      print('👤 Motorista atual: $user');
      
      // 2. Buscar TODAS as viagens
      final response = await get('/trips/');
      
      // 3. Verificar tipo e extrair lista
      List<dynamic> todas = [];
      if (response is List) {
        todas = response;
      } else if (response is Map && response.containsKey('results')) {
        todas = response['results'];
      }
      
      print('📊 Total de viagens no sistema: ${todas.length}');
      
      // 4. Analisar cada viagem
      for (var trip in todas) {
        print('---');
        print('🆔 ID: ${trip['id']}');
        print('📌 Status: ${trip['status']}');
        print('👤 Driver ID: ${trip['driver']}');
        print('👤 Motorista atual ID: ${user['id']}');
        print('🎯 Coincide? ${trip['driver'] == user['id']}');
        print('💰 Preço: ${trip['price']}');
        print('📍 Origem: ${trip['pickup_address']}');
        print('🏁 Destino: ${trip['dropoff_address']}');
      }
      
      // 5. Filtrar manualmente
      final minhasViagens = todas.where((trip) {
        return trip['driver'] == user['id'] && 
               (trip['status'] == 'ACCEPTED' || trip['status'] == 'STARTED');
      }).toList();
      
      print('🎯 MINHAS VIAGENS (filtro manual): ${minhasViagens.length}');
      
    } catch (e) {
      print('❌ Erro: $e');
    }
  }

  // ===== MÉTODO MELHORADO PARA BUSCAR ENDEREÇO DETALHADO =====
// ===== MÉTODO MELHORADO PARA BUSCAR ENDEREÇO DETALHADO =====
// ===== MÉTODO MELHORADO PARA BUSCAR ENDEREÇO DETALHADO =====
static Future<String> getDetailedAddressFromCoordinates(double lat, double lng) async {
  try {
    print('📍 Buscando endereço detalhado para: $lat, $lng');
    
    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
      headers: {
        'User-Agent': 'METY Driver App',
        'Accept-Language': 'pt-BR,pt;q=0.9',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['address'] != null) {
        final address = data['address'];
        
        String bairro = address['suburb'] ?? 
                       address['neighbourhood'] ?? 
                       address['quarter'] ?? '';
        
        String rua = address['road'] ?? 
                    address['pedestrian'] ?? 
                    address['street'] ?? '';
        
        String cidade = address['city'] ?? 
                       address['town'] ?? 
                       address['village'] ?? '';
        
        String provincia = address['state'] ?? address['province'] ?? '';
        
        List<String> partes = [];
        if (rua.isNotEmpty) partes.add(rua);
        if (bairro.isNotEmpty) partes.add(bairro);
        if (cidade.isNotEmpty) partes.add(cidade);
        if (provincia.isNotEmpty && !partes.contains(provincia)) partes.add(provincia);
        
        if (partes.isNotEmpty) {
          return partes.join(', ');
        }
      }
      
      // Se não conseguir endereço detalhado, mostra que é a localização do passageiro
      return '📍 Localização do passageiro';
    }
    
    return '📍 Localização do passageiro';
  } catch (e) {
    print('❌ Erro ao buscar endereço: $e');
    return '📍 Localização do passageiro';
  }
}


  // ===== CANCELAR VIAGEM =====
  static Future<Map<String, dynamic>?> cancelTrip(int tripId) async {
    try {
      print('❌ Cancelando viagem #$tripId...');
      final response = await post('/trips/$tripId/cancel/', {});
      print('✅ Viagem cancelada');
      return response;
    } catch (e) {
      print('❌ Erro ao cancelar: $e');
      return null;
    }
  }


}
