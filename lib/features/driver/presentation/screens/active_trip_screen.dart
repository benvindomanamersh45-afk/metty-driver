import 'package:flutter/material.dart';
import 'package:metty_driver_novo/core/theme/app_colors.dart';
import 'package:metty_driver_novo/core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  
  late Map<String, dynamic> _trip;
  bool _isLoading = false;
  bool _mapaCarregado = false;
  String? _passengerPhone;
  String _pickupAddress = '';
  String _pickupReference = ''; // NOVO CAMPO
  String _destinationAddress = '';

  // Controladores do mapa
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

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
        print('📍 Coordenadas do passageiro: $pickupLat, $pickupLng');
        
        _pickupAddress = await ApiClient.getDetailedAddressFromCoordinates(
          pickupLat,
          pickupLng,
        );
        
        print('📍 Endereço encontrado: $_pickupAddress');
        
        if (_pickupAddress == 'Localização do passageiro' || _pickupAddress.isEmpty) {
          _pickupAddress = _trip['pickup_address'] ?? 'Localização do passageiro';
        }
      } else {
        _pickupAddress = _trip['pickup_address'] ?? 'Localização do passageiro';
        print('⚠️ Passageiro não compartilhou localização exata');
      }

      // NOVO: Ponto de referência
      _pickupReference = _trip['pickup_reference'] ?? '';

      // Endereço de destino - COM CONVERSÃO SEGURA
      final destLat = _safeToDouble(_trip['destination_latitude']);
      final destLng = _safeToDouble(_trip['destination_longitude']);
      
      if (destLat != null && destLng != null) {
        _destinationAddress = await ApiClient.getDetailedAddressFromCoordinates(
          destLat,
          destLng,
        );
        
        if (_destinationAddress == 'Localização do passageiro' || _destinationAddress.isEmpty) {
          _destinationAddress = _trip['destination_address'] ?? 'Destino';
        }
      } else {
        _destinationAddress = _trip['destination_address'] ?? 'Destino';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erro: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupMarkers() {
    final pickupLat = _safeToDouble(_trip['pickup_latitude']);
    final pickupLng = _safeToDouble(_trip['pickup_longitude']);
    final destLat = _safeToDouble(_trip['destination_latitude']);
    final destLng = _safeToDouble(_trip['destination_longitude']);

    if (pickupLat != null && pickupLng != null) {
      _pickupLatLng = LatLng(pickupLat, pickupLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Passageiro',
            snippet: _pickupAddress,
          ),
        ),
      );
    }

    if (destLat != null && destLng != null) {
      _destinationLatLng = LatLng(destLat, destLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: _destinationAddress,
          ),
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

  Future<void> _startTrip() async {
    setState(() => _isLoading = true);
    try {
      final updated = await ApiClient.startTrip(_trip['id']);
      setState(() {
        _trip = updated;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem iniciada!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTrip() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.completeTrip(_trip['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viagem concluída! Ganho: ${_trip['price']} Kz'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Erro ao completar: $e');
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao completar viagem'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirMapaOrigem() async {
    if (_pickupLatLng != null) {
      final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else {
      _mostrarMensagemSemLocalizacao();
    }
  }

  Future<void> _abrirMapaDestino() async {
    if (_destinationLatLng != null) {
      final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else {
      _mostrarMensagemSemLocalizacao();
    }
  }

  Future<void> _abrirRota() async {
    if (_pickupLatLng != null && _destinationLatLng != null) {
      final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else {
      _mostrarMensagemSemLocalizacao();
    }
  }

  void _mostrarMensagemSemLocalizacao() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passageiro não compartilhou localização exata'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _ajustarCameraParaAmbos() {
    if (_pickupLatLng != null && _destinationLatLng != null && _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _pickupLatLng!.latitude < _destinationLatLng!.latitude 
              ? _pickupLatLng!.latitude 
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude < _destinationLatLng!.longitude 
              ? _pickupLatLng!.longitude 
              : _destinationLatLng!.longitude,
        ),
        northeast: LatLng(
          _pickupLatLng!.latitude > _destinationLatLng!.latitude 
              ? _pickupLatLng!.latitude 
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude > _destinationLatLng!.longitude 
              ? _pickupLatLng!.longitude 
              : _destinationLatLng!.longitude,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _trip['status'] ?? 'ACCEPTED';
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          status == 'ACCEPTED' ? 'BUSCAR PASSAGEIRO' : 'VIAGEM EM ANDAMENTO',
          style: const TextStyle(fontSize: 16),
        ),
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
          : Column(
              children: [
                // Informações da viagem (parte superior)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade900,
                  child: Column(
                    children: [
                      // Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status == 'ACCEPTED' 
                              ? Colors.orange.shade900 
                              : Colors.blue.shade900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == 'ACCEPTED' 
                                  ? Icons.timer 
                                  : Icons.directions_car,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status == 'ACCEPTED' 
                                  ? 'A caminho do passageiro' 
                                  : 'Em andamento',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Passageiro
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.metyPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PASSAGEIRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _trip['passenger_name'] ?? 'Desconhecido',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_passengerPhone != null)
                                  Text(
                                    _passengerPhone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Origem (local do passageiro)
                      Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LOCAL DO PASSAGEIRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _pickupAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: _abrirMapaOrigem,
                            tooltip: 'Ver no mapa',
                          ),
                        ],
                      ),

                      // NOVO: Ponto de Referência
                      if (_pickupReference.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 32),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.metyOrange, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PONTO DE REFERÊNCIA',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _pickupReference,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.metyOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Destino
                      Row(
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
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _destinationAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.green),
                            onPressed: _abrirMapaDestino,
                            tooltip: 'Ver no mapa',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Preço
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PREÇO',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_trip['price']} Kz',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.metyGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Mapa (parte do meio)
                if (_pickupLatLng != null)
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _pickupLatLng!,
                                zoom: 16,
                              ),
                              markers: _markers,
                              onMapCreated: (GoogleMapController controller) {
                                print('🗺️ Mapa criado com sucesso!');
                                _mapController = controller;
                                if (_destinationLatLng != null) {
                                  _ajustarCameraParaAmbos();
                                }
                                setState(() {
                                  _mapaCarregado = true;
                                });
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: true,
                              compassEnabled: true,
                            ),
                            if (!_mapaCarregado)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: AppColors.metyPurple),
                                      SizedBox(height: 10),
                                      Text(
                                        'Carregando mapa...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                        color: Colors.grey.shade900,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_rounded, size: 60, color: Colors.white24),
                            SizedBox(height: 16),
                            Text(
                              'Localização não disponível',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'O passageiro não compartilhou a localização exata',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Botões de ação (parte inferior)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (status == 'ACCEPTED')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _startTrip,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('INICIAR VIAGEM'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _abrirRota,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('VER ROTA'),
                              ),
                            ),
                          ],
                        ),

                      if (status == 'STARTED')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _completeTrip,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('COMPLETAR VIAGEM'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _abrirRota,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('ROTA'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
