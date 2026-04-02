import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/active_trip_screen.dart';

class AcceptedTripsScreen extends StatefulWidget {
  const AcceptedTripsScreen({super.key});

  @override
  State<AcceptedTripsScreen> createState() => _AcceptedTripsScreenState();
}

class _AcceptedTripsScreenState extends State<AcceptedTripsScreen> {
  List<dynamic> _viagens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarViagens();
  }

  Future<void> _carregarViagens() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 ===== BUSCANDO VIAGENS ACEITAS =====');
      final trips = await ApiClient.getAcceptedTrips();
      print('📦 Resultado final: ${trips.length} viagens aceitas');
      
      setState(() {
        _viagens = trips;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro: $e');
      setState(() => _isLoading = false);
    }
  }

  // ===== MÉTODO DE TESTE COM ALERTA VISUAL - CORRIGIDO =====
  Future<void> _testarComAlerta() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 ===== TESTE COM ALERTA =====');
      
      // 1. Pegar usuário atual
      final user = await ApiClient.get('/users/me/');
      print('👤 Motorista atual: $user');
      
      // 2. Buscar TODAS as viagens - COM VERIFICAÇÃO DE TIPO
      final response = await ApiClient.get('/trips/');
      print('📦 Tipo da resposta: ${response.runtimeType}');
      
      // IMPORTANTE: Verificar se response é uma List
      List<dynamic> todas = [];
      if (response is List) {
        todas = response;
        print('📊 Total de viagens no sistema: ${todas.length}');
      } else if (response is Map) {
        // Se for um Map, pode ser que tenha um campo 'results' (paginação)
        if (response.containsKey('results')) {
          todas = response['results'];
          print('📊 Total de viagens (results): ${todas.length}');
        } else {
          print('⚠️ Resposta não é uma lista: $response');
        }
      }
      
      // 3. Criar lista de detalhes para o alerta
      List<String> detalhes = [];
      detalhes.add('📊 TOTAL DE VIAGENS: ${todas.length}');
      detalhes.add('👤 SEU ID: ${user['id']}');
      detalhes.add('---');
      
      if (todas.isEmpty) {
        detalhes.add('❌ NENHUMA VIAGEM ENCONTRADA');
      } else {
        for (var trip in todas) {
          detalhes.add('🆔 ID: ${trip['id']}');
          detalhes.add('📌 Status: ${trip['status']}');
          detalhes.add('👤 Driver ID: ${trip['driver']}');
          detalhes.add('💰 Preço: ${trip['price']}');
          detalhes.add('---');
        }
        
        // Filtrar suas viagens
        final minhasViagens = todas.where((trip) {
          return trip['driver'] == user['id'];
        }).toList();
        
        detalhes.add('🎯 SUAS VIAGENS (driver = seu ID): ${minhasViagens.length}');
        
        // Filtrar viagens com status ACCEPTED
        final aceitas = todas.where((trip) {
          return trip['status'] == 'ACCEPTED';
        }).toList();
        
        detalhes.add('📌 VIAGENS ACEITAS (status ACCEPTED): ${aceitas.length}');
      }
      
      setState(() => _isLoading = false);
      
      // MOSTRAR ALERTA COM OS RESULTADOS
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resultado do Teste'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detalhes.map((text) => Text(text)).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      // MOSTRAR ERRO
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ERRO'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACCEPTED': return 'Aguardando início';
      case 'STARTED': return 'Em andamento';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED': return Colors.orange;
      case 'STARTED': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MINHAS VIAGENS'),
        backgroundColor: AppColors.metyPurple,
        actions: [
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarViagens,
            tooltip: 'Atualizar',
          ),
          // ===== BOTÃO DE TESTE CORRIGIDO =====
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            onPressed: _testarComAlerta,
            tooltip: 'Testar com Alerta',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.metyPurple))
          : _viagens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma viagem aceita',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'As viagens que você aceitar aparecerão aqui',
                        style: TextStyle(fontSize: 14, color: Colors.white38),
                      ),
                      const SizedBox(height: 20),
                      // Botão de teste na tela vazia também
                      ElevatedButton.icon(
                        onPressed: _testarComAlerta,
                        icon: const Icon(Icons.bug_report_rounded),
                        label: const Text('TESTAR API'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _viagens.length,
                  itemBuilder: (context, index) {
                    final v = _viagens[index];
                    final statusColor = _getStatusColor(v['status']);
                    
                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActiveTripScreen(trip: v),
                            ),
                          ).then((_) => _carregarViagens());
                        },
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(
                            v['status'] == 'ACCEPTED' ? Icons.timer : Icons.directions_car,
                            color: statusColor,
                          ),
                        ),
                        title: Text(
                          v['passenger_name'] ?? 'Desconhecido',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(v['status']),
                              style: TextStyle(color: statusColor, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              v['pickup_address'] ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${v['price']} Kz',
                          style: const TextStyle(
                            color: AppColors.metyGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
