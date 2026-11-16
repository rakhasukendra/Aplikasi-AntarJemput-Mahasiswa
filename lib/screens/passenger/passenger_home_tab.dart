import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/ride_request.dart';
import '../../models/ride_location.dart';
import '../../services/ride_repository.dart';
import '../../services/trip_repository.dart';
import '../../models/trip.dart';
import '../../utils/format.dart';
import '../../widgets/location_picker_map.dart';

class PassengerHomeTab extends StatefulWidget {
  /// Dipanggil setelah pesanan berhasil dibuat agar peta perjalanan dibuka.
  final ValueChanged<RideRequest> onOrderCreated;
  final String? passengerId;
  final TripRepository? tripRepository;
  final bool localMode;

  const PassengerHomeTab({
    super.key,
    required this.onOrderCreated,
    this.passengerId,
    this.tripRepository,
    this.localMode = false,
  });

  @override
  State<PassengerHomeTab> createState() => _PassengerHomeTabState();
}

class _PassengerHomeTabState extends State<PassengerHomeTab> {
  static const _campusCenter = LatLng(-7.558, 110.856);

  static const _pickupSuggestions = [
    'Gerbang Utama Kampus Barat',
    'Gedung Kuliah Bersama',
    'Perpustakaan Pusat',
    'Asrama Putri',
  ];
  static const _destSuggestions = [
    'Stasiun Kampus',
    'Kantin Pusat',
    'Fakultas Teknik',
    'Area Kos Putri Sekarwangi',
  ];

  // (label, menit dari sekarang)
  static const _timeOptions = [
    ('10 menit lagi', 10),
    ('30 Menit lagi', 30),
    ('1 Jam lagi', 60),
  ];
  static const _customIndex = 3; // opsi "Pilih waktu sendiri"

  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _homeMapController = MapController();
  int _timeIndex = 0;
  DateTime? _customTime;
  int _count = 1;
  int _stepIndex = 0;
  RideLocation? _pickupLocation;
  RideLocation? _destinationLocation;

  @override
  void initState() {
    super.initState();
    _pickupCtrl.addListener(() => setState(() {}));
    _destCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    _homeMapController.dispose();
    super.dispose();
  }

  /// Geser kamera peta agar menampilkan marker yang sudah dipilih.
  void _syncMapCamera() {
    final p = _pickupLocation;
    final d = _destinationLocation;
    if (p != null && d != null) {
      final midLat = (p.latitude + d.latitude) / 2;
      final midLng = (p.longitude + d.longitude) / 2;
      _homeMapController.move(LatLng(midLat, midLng), 14);
    } else if (p != null) {
      _homeMapController.move(LatLng(p.latitude, p.longitude), 15);
    } else if (d != null) {
      _homeMapController.move(LatLng(d.latitude, d.longitude), 15);
    }
  }

  // ---------- Logika ----------

  void _swap() {
    final temp = _pickupCtrl.text;
    _pickupCtrl.text = _destCtrl.text;
    _destCtrl.text = temp;
  }

  DateTime? get _scheduledAt {
    if (_timeIndex == _customIndex) return _customTime;
    return DateTime.now().add(Duration(minutes: _timeOptions[_timeIndex].$2));
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _onTimeChanged(int? index) async {
    if (index == null) return;
    if (index != _customIndex) {
      setState(() => _timeIndex = index);
      return;
    }
    final picked = await _pickDateTime();
    if (picked != null) {
      setState(() {
        _timeIndex = index;
        _customTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_stepIndex != 1) return;
    if (!_formKey.currentState!.validate()) return;

    final scheduled = _scheduledAt;
    if (scheduled == null) {
      _showMessage('Pilih waktu jemput dulu');
      return;
    }
    if (scheduled.isBefore(DateTime.now())) {
      _showMessage('Waktu jemput tidak boleh di masa lalu');
      return;
    }

    var rideId = DateTime.now().microsecondsSinceEpoch.toString();
    final repository = widget.tripRepository;
    if (repository?.isConfigured == true && widget.passengerId != null) {
      if (_pickupLocation == null || _destinationLocation == null) {
        _showMessage(
          'Pilih titik jemput dan tujuan lewat peta agar perjalanan dapat dilacak.',
        );
        return;
      }
      try {
        rideId = await repository!.createTrip(
          TripDraft(
            passengerId: widget.passengerId!,
            pickup: _pickupLocation!,
            destination: _destinationLocation!,
            passengerCount: _count,
            scheduledAt: scheduled,
          ),
        );
      } catch (error) {
        _showMessage('Pesanan gagal dikirim. Periksa koneksi lalu coba lagi.');
        return;
      }
    }

    final request = RideRequest(
      id: rideId,
      pickup: _pickupCtrl.text.trim(),
      destination: _destCtrl.text.trim(),
      scheduledAt: scheduled,
      passengerCount: _count,
      pickupLocation: _pickupLocation,
      destinationLocation: _destinationLocation,
    );
    RideRepository.instance.add(request);

    // Reset form
    _pickupCtrl.clear();
    _destCtrl.clear();
    _pickupLocation = null;
    _destinationLocation = null;
    setState(() {
      _timeIndex = 0;
      _customTime = null;
      _count = 1;
    });

    _showMessage('Pesanan berhasil diajukan');
    widget.onOrderCreated(request);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _continueToSchedule() {
    if (_formKey.currentState!.validate()) {
      setState(() => _stepIndex = 1);
    }
  }

  Future<void> _pickLocation({required bool pickup}) async {
    final selected = await showModalBottomSheet<RideLocation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: LocationPickerMap(
          title: pickup ? 'Pilih titik jemput' : 'Pilih tujuan',
          initialLocation: pickup ? _pickupLocation : _destinationLocation,
          onLocationSelected: (location) =>
              Navigator.pop(sheetContext, location),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickupLocation = selected;
        _pickupCtrl.text = selected.label;
      } else {
        _destinationLocation = selected;
        _destCtrl.text = selected.label;
      }
    });
    _syncMapCamera();
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sheetWidth = constraints.maxWidth > 560
              ? 560.0
              : constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              _homeMap(),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: sheetWidth,
                    child: DraggableScrollableSheet(
                      key: ValueKey(_stepIndex),
                      initialChildSize: _stepIndex == 0 ? 0.72 : 0.54,
                      minChildSize: 0.42,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (context, scrollController) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4D9CE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Langkah ${_stepIndex + 1} dari 2',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF414B42),
                              ),
                            ),
                            if (widget.localMode) ...[
                              const SizedBox(height: 8),
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Mode lokal: pesanan hanya tersimpan di perangkat ini dan tidak dikirim ke driver.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _stepIndex == 0 ? 0.5 : 1,
                            ),
                            const SizedBox(height: 16),
                            if (_stepIndex == 0) ...[
                              _searchCard(),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _continueToSchedule,
                                  child: const Text(
                                    'Lanjut',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              _scheduleCard(),
                              const SizedBox(height: 12),
                              _safetyCard(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _stepIndex = 0),
                                      child: const Text('Kembali'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _submit,
                                      child: const Text(
                                        'Pesan jemput',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Peta latar untuk area kampus dan marker lokasi.
  Widget _homeMap() {
    final primary = Theme.of(context).colorScheme.primary;
    final markers = <Marker>[];

    if (_pickupLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
          width: 40,
          height: 40,
          child: Icon(Icons.location_on, color: primary, size: 36),
        ),
      );
    }
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            _destinationLocation!.latitude,
            _destinationLocation!.longitude,
          ),
          width: 40,
          height: 40,
          child: Icon(Icons.flag, color: Colors.green.shade700, size: 32),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _homeMapController,
          options: MapOptions(
            initialCenter: _campusCenter,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            onTap: (_, _) => _pickLocation(pickup: _pickupLocation == null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.example.aplikasi_antarjemput_mahasiswa',
              maxZoom: 19,
            ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),

        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _pickupLocation == null && _destinationLocation == null
                    ? 'Ketuk peta untuk pilih lokasi'
                    : _pickupLocation != null && _destinationLocation != null
                    ? 'Jemput & tujuan dipilih'
                    : _pickupLocation != null
                    ? 'Jemput dipilih. Ketuk peta untuk memilih tujuan'
                    : 'Tujuan dipilih. Ketuk peta untuk memilih titik jemput',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Titik jemput dan tujuan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // --- Titik jemput ---
          _label('Titik jemput *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pickupCtrl,
            decoration: _fieldDecoration(
              hint: 'Masukkan titik jemput',
              icon: Icon(Icons.location_on, color: primary),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Titik jemput wajib diisi'
                : null,
          ),
          _mapPickerAction(
            label: 'Pilih titik jemput lewat peta',
            onPressed: () => _pickLocation(pickup: true),
          ),
          const SizedBox(height: 8),
          _chips(_pickupSuggestions, _pickupCtrl),

          // --- Tombol tukar ---
          Center(
            child: IconButton.outlined(
              onPressed: _swap,
              icon: const Icon(Icons.swap_vert),
            ),
          ),

          // --- Tujuan ---
          _label('Tujuan *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _destCtrl,
            decoration: _fieldDecoration(
              hint: 'Masukkan tujuan',
              icon: Icon(Icons.flag, color: Colors.green.shade700),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Tujuan wajib diisi';
              if (v.trim().toLowerCase() ==
                  _pickupCtrl.text.trim().toLowerCase()) {
                return 'Tujuan tidak boleh sama dengan titik jemput';
              }
              return null;
            },
          ),
          _mapPickerAction(
            label: 'Pilih tujuan lewat peta',
            onPressed: () => _pickLocation(pickup: false),
          ),
          const SizedBox(height: 8),
          _chips(_destSuggestions, _destCtrl),
        ],
      ),
    );
  }

  Widget _scheduleCard() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atur jadwal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _IconLabel(Icons.schedule, 'Waktu Jemput'),
                    const SizedBox(height: 6),
                    _timeDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _IconLabel(Icons.group_outlined, 'Penumpang'),
                    const SizedBox(height: 6),
                    _passengerStepper(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeDropdown() {
    final customLabel = _customTime == null
        ? 'Pilih waktu sendiri…'
        : formatDateTime(_customTime!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _timeIndex,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          for (var i = 0; i < _timeOptions.length; i++)
            DropdownMenuItem(
              value: i,
              child: Text(_timeOptions[i].$1, overflow: TextOverflow.ellipsis),
            ),
          DropdownMenuItem(
            value: _customIndex,
            child: Text(customLabel, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: _onTimeChanged,
      ),
    );
  }

  Widget _passengerStepper() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove,
            color: Colors.grey.shade300,
            iconColor: Colors.black54,
            onTap: _count > 1 ? () => setState(() => _count--) : null,
          ),
          Text(
            '$_count Orang',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          _StepButton(
            icon: Icons.add,
            color: primary,
            iconColor: Colors.white,
            onTap: _count < 4 ? () => setState(() => _count++) : null,
          ),
        ],
      ),
    );
  }

  Widget _safetyCard() {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield_outlined, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keselamatan perjalanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Gunakan helm selama perjalanan.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper kecil ----------

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  );

  Widget _mapPickerAction({
    required String label,
    required VoidCallback onPressed,
  }) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.map_outlined, size: 18),
      label: Text(label),
    ),
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget icon,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: icon,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _chips(List<String> items, TextEditingController target) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 14)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => target.text = s,
                ),
              ),
          ],
        ),
      );
}

// ================= Widget pendukung =================

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  const _StepButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
