import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/trip_details_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/accepted_trips_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/driver_history_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/widgets/driver_card.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<dynamic> _viagens = [];
  bool _isLoading = true;
  String? _driverName;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _carregarMotorista();
    await _carregarViagens();
  }

  Future<void> _carregarMotorista() async {
    try {
      final user = await ApiClient.getCurrentUser();
      setState(() => _driverName = user['full_name'] ?? 'Motorista');
    } catch (e) {
      print('Erro ao carregar motorista: $e');
    }
  }

  Future<void> _carregarViagens() async {
    setState(() => _isLoading = true);
    try {
      final trips = await ApiClient.getRecentPendingTrips();
      setState(() {
        _viagens = trips;
        _isLoading = false;
      });
      print('✅ Viagens recentes carregadas: ${trips.length}');
    } catch (e) {
      print('❌ Erro: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'SAIR DA CONTA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiClient.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MOTORISTA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.metyPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverHistoryScreen(),
                ),
              );
            },
            tooltip: 'Histórico',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AcceptedTripsScreen(),
                ),
              );
            },
            tooltip: 'Minhas viagens',
          ),
          if (_driverName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _driverName!.split(' ').first,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.green,
            child: const Center(
              child: Text(
                '🟢 ONLINE - Recebendo solicitações',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.metyPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.metyPurple.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_viagens.length} viagens disponíveis',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _carregarViagens,
                  backgroundColor: Colors.orange,
                  mini: true,
                  child: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.metyPurple))
                : _viagens.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 80, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma viagem recente',
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Viagens com mais de 2 horas não aparecem',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _viagens.length,
                        itemBuilder: (context, index) {
                          final v = _viagens[index];
                          return DriverCard(
                            trip: v,
                            onAccept: () async {
                              // 👇 Vai para detalhes da viagem
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripDetailsScreen(trip: v),
                                ),
                              );
                              // 👇 Se voltar com resultado true, recarrega a lista
                              if (result == true) {
                                _carregarViagens();
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
