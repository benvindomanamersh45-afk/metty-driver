import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/theme/app_gradients.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Map<String, dynamic> _trip;
  bool _isLoading = false;
  String? _passengerPhone;
  String _pickupAddress = '';
  String _pickupReference = '';
  String _destinationAddress = '';

  // Controladores do mapa
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _pickupLatLng;

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

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadPassengerDetails();
    _setupMarkers();
  }

  Future<void> _loadPassengerDetails() async {
    setState(() => _isLoading = true);
    try {
      // Buscar telefone do passageiro
      final passengerId = _trip['passenger'];
      if (passengerId != null) {
        final passenger = await ApiClient.getPassengerDetails(passengerId);
        setState(() {
          _passengerPhone = passenger?['phone']?.toString() ?? '';
        });
      }

      // Buscar endereços detalhados - COM CONVERSÃO SEGURA
      final pickupLat = _safeToDouble(_trip['pickup_latitude']);
      final pickupLng = _safeToDouble(_trip['pickup_longitude']);
      
      if (pickupLat != null && pickupLng != null) {
        _pickupAddress = await ApiClient.getAddressFromCoordinates(
          pickupLat,
          pickupLng,
        );
      } else {
        _pickupAddress = _trip['pickup_address'] ?? 'Localização atual';
      }

      // Ponto de referência
      _pickupReference = _trip['pickup_reference'] ?? '';
      _destinationAddress = _trip['destination_address'] ?? 'Destino';

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupMarkers() {
    final pickupLat = _safeToDouble(_trip['pickup_latitude']);
    final pickupLng = _safeToDouble(_trip['pickup_longitude']);
    
    if (pickupLat != null && pickupLng != null) {
      _pickupLatLng = LatLng(pickupLat, pickupLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Passageiro'),
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    if (_passengerPhone != null && _passengerPhone!.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: _passengerPhone!,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    }
  }

  Future<void> _acceptTrip() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.acceptTrip(_trip['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem aceita com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _recusarViagem() async {
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
      setState(() => _isLoading = true);
      try {
        await ApiClient.cancelTrip(_trip['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Viagem recusada'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirMapa() async {
    if (_pickupLatLng != null) {
      final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DETALHES DA VIAGEM'),
        backgroundColor: AppColors.metyPurple,
        actions: [
          if (_passengerPhone != null)
            IconButton(
              icon: const Icon(Icons.phone_rounded),
              onPressed: _makePhoneCall,
              tooltip: 'Ligar para passageiro',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.metyPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Mapa (se tiver coordenadas)
                  if (_pickupLatLng != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _pickupLatLng!,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onMapCreated: (controller) => _mapController = controller,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.timer, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'PENDENTE',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card do passageiro
                  Card(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PASSAGEIRO',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.metyPurple,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _trip['passenger_name'] ?? 'Desconhecido',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_passengerPhone != null)
                                      Text(
                                        _passengerPhone!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
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
                  ),

                  const SizedBox(height: 16),

                  // Card da origem
                  Card(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ORIGEM',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pickupAddress,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_pickupLatLng != null)
                                IconButton(
                                  icon: const Icon(Icons.map, color: Colors.blue),
                                  onPressed: _abrirMapa,
                                ),
                            ],
                          ),
                          // Ponto de Referência
                          if (_pickupReference.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppColors.metyOrange, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PONTO DE REFERÊNCIA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _pickupReference,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.metyOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card do destino
                  Card(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESTINO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _destinationAddress,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preço
                  Card(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PREÇO',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_trip['price']} Kz',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.metyGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão ACEITAR
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _acceptTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.metyPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ACEITAR VIAGEM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botão RECUSAR
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _recusarViagem,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'RECUSAR VIAGEM',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
