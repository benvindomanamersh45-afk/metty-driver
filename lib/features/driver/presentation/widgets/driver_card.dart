import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onAccept;

  const DriverCard({
    super.key,
    required this.trip,
    required this.onAccept,
  });

  // ===== MÉTODO AUXILIAR PARA CONVERSÃO SEGURA =====
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return double.parse(value);
      } else if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      }
    } catch (e) {
      print('❌ Erro ao converter para double: $value');
    }
    return null;
  }

  String _getEnderecoResumido(String endereco) {
    if (endereco.length > 30) {
      return '${endereco.substring(0, 27)}...';
    }
    return endereco;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'PREMIUM': return AppColors.metyOrange;
      case 'COMFORT': return AppColors.metyBlue;
      default: return AppColors.metyGreen;
    }
  }

  Future<void> _abrirMapa(dynamic lat, dynamic lng) async {
    double? latitude = _safeToDouble(lat);
    double? longitude = _safeToDouble(lng);
    
    if (latitude == null || longitude == null) {
      print('❌ Coordenadas inválidas: lat=$lat, lng=$lng');
      return;
    }
    
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  String _calcularTempo(String? dataStr) {
    if (dataStr == null) return 'agora';
    try {
      final data = DateTime.parse(dataStr);
      final agora = DateTime.now();
      final diferenca = agora.difference(data);
      
      if (diferenca.inMinutes < 1) return 'agora';
      if (diferenca.inMinutes < 60) return '${diferenca.inMinutes} min';
      if (diferenca.inHours < 24) return '${diferenca.inHours} h';
      return '${diferenca.inDays} d';
    } catch (e) {
      return 'agora';
    }
  }

  Future<void> _recusarViagem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'RECUSAR VIAGEM',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tem certeza que deseja recusar esta viagem?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('RECUSAR'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ApiClient.cancelTrip(trip['id']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Viagem recusada'),
              backgroundColor: Colors.orange,
            ),
          );
          // Recarregar a lista
          onAccept();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao recusar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(trip['category'] ?? 'ECONOMIC');
    final pickupLat = trip['pickup_latitude'];
    final pickupLng = trip['pickup_longitude'];
    final hasReference = trip['pickup_reference'] != null && trip['pickup_reference'].toString().isNotEmpty;
    
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
            // Cabeçalho com passageiro e tempo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: categoryColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: categoryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['passenger_name'] ?? 'Desconhecido',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Solicitada há ${_calcularTempo(trip['requested_at'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tempo estimado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${trip['estimated_duration'] ?? 5} min',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ORIGEM (com mapa)
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORIGEM',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getEnderecoResumido(trip['pickup_address'] ?? ''),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (pickupLat != null && pickupLng != null)
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _abrirMapa(pickupLat, pickupLng),
                    tooltip: 'Ver no mapa',
                  ),
              ],
            ),

            // Indicador de Ponto de Referência
            if (hasReference)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 30),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.metyOrange, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '📍 ${_getEnderecoResumido(trip['pickup_reference'].toString())}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.metyOrange,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // DESTINO
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag, color: Colors.green, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESTINO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getEnderecoResumido(trip['destination_address'] ?? ''),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preço e botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREÇO',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${trip['price']} Kz',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.metyGreen,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Botão RECUSAR
                    OutlinedButton(
                      onPressed: () => _recusarViagem(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        minimumSize: const Size(80, 45),
                      ),
                      child: const Text('RECUSAR'),
                    ),
                    const SizedBox(width: 8),
                    // Botão ACEITAR
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.metyPurple,
                        minimumSize: const Size(100, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ACEITAR'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
