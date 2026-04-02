import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  List<dynamic> _viagens = [];
  bool _isLoading = true;
  double _totalGanhos = 0;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      // Buscar todas as viagens
      final todas = await ApiClient.getAllTrips();
      
      // Pegar usuário atual
      final user = await ApiClient.getCurrentUser();
      final driverId = user['id'];
      
      // Filtrar viagens COMPLETED deste motorista
      final minhasViagens = todas.where((trip) {
        return trip['driver'] == driverId && 
               trip['status'] == 'COMPLETED';
      }).toList();
      
      // Calcular total de ganhos
      double total = 0;
      for (var trip in minhasViagens) {
        total += double.parse(trip['price'].toString());
      }
      
      setState(() {
        _viagens = minhasViagens;
        _totalGanhos = total;
        _isLoading = false;
      });
      
      print('✅ Histórico carregado: ${minhasViagens.length} viagens');
      
    } catch (e) {
      print('❌ Erro: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatarData(String? dataStr) {
    if (dataStr == null) return 'Data desconhecida';
    try {
      final data = DateTime.parse(dataStr);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    } catch (e) {
      return 'Data desconhecida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HISTÓRICO DE VIAGENS'),
        backgroundColor: AppColors.metyPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarHistorico,
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
                      Icon(Icons.history_rounded, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma viagem concluída',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suas viagens aparecerão aqui',
                        style: TextStyle(fontSize: 14, color: Colors.white38),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Card de ganhos totais
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.metyPurple, Colors.deepPurple],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GANHOS TOTAIS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Histórico completo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_totalGanhos.toStringAsFixed(0)} Kz',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de viagens
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _viagens.length,
                        itemBuilder: (context, index) {
                          final v = _viagens[index];
                          return Card(
                            color: Colors.grey.shade900,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.check, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              v['passenger_name'] ?? 'Desconhecido',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _formatarData(v['completed_at'] ?? v['updated_at']),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${v['price']} Kz',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.metyGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, color: Colors.blue, size: 12),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                v['pickup_address'] ?? 'Origem',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.flag, color: Colors.green, size: 12),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                v['destination_address'] ?? 'Destino',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
