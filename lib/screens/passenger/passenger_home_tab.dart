import 'package:flutter/material.dart';
import '../../models/ride_request.dart';
import '../../services/ride_repository.dart';
import '../../utils/format.dart';

class PassengerHomeTab extends StatefulWidget {
  /// Dipanggil setelah pesanan berhasil dibuat (untuk pindah ke tab Riwayat).
  final VoidCallback onOrderCreated;

  const PassengerHomeTab({super.key, required this.onOrderCreated});

  @override
  State<PassengerHomeTab> createState() => _PassengerHomeTabState();
}

class _PassengerHomeTabState extends State<PassengerHomeTab> {
  // Data pengguna sementara. Nanti diganti dari data login (Anggota 1/4).
  static const _userName = 'Penumpang';
  static const _userInfo = 'NIM: 21102045 • Ilmu Komputer';

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
    ('Sekarang (10 Menit lagi)', 10),
    ('30 Menit lagi', 30),
    ('1 Jam lagi', 60),
  ];
  static const _customIndex = 3; // opsi "Pilih waktu sendiri"

  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  int _timeIndex = 0;
  DateTime? _customTime;
  int _count = 1;

  @override
  void initState() {
    super.initState();
    // Supaya kartu estimasi tarif ikut berubah saat teks diketik.
    _pickupCtrl.addListener(() => setState(() {}));
    _destCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
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
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
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

  // Estimasi SEMENTARA: belum ada peta/jarak asli, jadi jarak dibuat
  // dummy dari panjang teks. Ganti dengan hitungan jarak sungguhan nanti.
  bool get _hasRoute =>
      _pickupCtrl.text.trim().isNotEmpty && _destCtrl.text.trim().isNotEmpty;
  double get _distanceKm =>
      1.0 + ((_pickupCtrl.text.trim() + _destCtrl.text.trim()).length % 50) / 10;
  int get _fareMin => ((_distanceKm * 2500) / 500).round() * 500;
  int get _fareMax => _fareMin + 2000;

  void _submit() {
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

    RideRepository.instance.add(
      RideRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        pickup: _pickupCtrl.text.trim(),
        destination: _destCtrl.text.trim(),
        scheduledAt: scheduled,
        passengerCount: _count,
      ),
    );

    // Reset form
    _pickupCtrl.clear();
    _destCtrl.clear();
    setState(() {
      _timeIndex = 0;
      _customTime = null;
      _count = 1;
    });

    _showMessage('Pesanan berhasil diajukan');
    widget.onOrderCreated();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _greetingCard(),
          const SizedBox(height: 12),
          _searchCard(),
          const SizedBox(height: 12),
          _mapCard(),
          const SizedBox(height: 12),
          _fareCard(),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submit,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pesan Antar Jemput',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _safetyCard(),
        ],
      ),
    );
  }

  Widget _greetingCard() {
    return _SectionCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, $_userName! 👋',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(_userInfo,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 18, color: Colors.green.shade800),
                const SizedBox(width: 6),
                Text('Penumpang\nTerverifikasi',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Cari Perjalanan Kampus',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.circle, size: 8, color: Colors.green.shade600),
              const SizedBox(width: 4),
              const Text('18 Pengemudi Aktif',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // --- Titik jemput ---
          _label('Titik Jemput *', 'Zona Halte / Gate'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pickupCtrl,
            decoration: _fieldDecoration(
              hint: 'Masukkan titik jemput',
              icon: Icon(Icons.location_on, color: primary),
              suffix: IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                // Simulasi "lokasi saya" sampai ada GPS sungguhan.
                onPressed: () => _pickupCtrl.text = _pickupSuggestions.first,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Titik jemput wajib diisi' : null,
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
          _label('Tujuan *', 'Area Kampus & Sekitarnya'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _destCtrl,
            decoration: _fieldDecoration(
              hint: 'Masukkan tujuan',
              icon: Icon(Icons.flag, color: Colors.green.shade700),
              suffix: const Icon(Icons.history, size: 20),
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
          const SizedBox(height: 8),
          _chips(_destSuggestions, _destCtrl),
          const SizedBox(height: 16),

          // --- Waktu & penumpang ---
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
          const SizedBox(height: 16),

          // --- Catatan ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 12),
                      children: [
                        TextSpan(text: 'Pastikan titik jemput berada di '),
                        TextSpan(
                            text: 'zona halte / titik kumpul resmi kampus',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: ' agar pengemudi mudah menemukanmu.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
        style: const TextStyle(fontSize: 12, color: Colors.black87),
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
          Text('$_count Orang',
              style: const TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _mapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Peta hanya ilustrasi. Nanti bisa diganti flutter_map/google_maps.
            Container(color: const Color(0xFFD7E3EC)),
            CustomPaint(painter: _MapPainter()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black54,
                child: Row(
                  children: [
                    const Icon(Icons.alt_route, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text('Rute Kampus Terverifikasi',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Live Telemetry',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fareCard() {
    final primary = Theme.of(context).colorScheme.primary;
    final fareText = _hasRoute
        ? '${formatRupiah(_fareMin)} – ${formatRupiah(_fareMax)}'
        : '-';

    return _SectionCard(
      color: const Color(0xFFE5E7EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.navigation_outlined, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jarak Perjalanan',
                        style: TextStyle(fontSize: 11)),
                    Text(
                      _hasRoute
                          ? '${_distanceKm.toStringAsFixed(1)} km (±8-12 menit)'
                          : '-',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Estimasi Tarif', style: TextStyle(fontSize: 11)),
                  Text(fareText,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Hemat s.d 50%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
                Text('Standar Keamanan Komunitas',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  'Helm Standar SNI & Verifikasi KTM Mahasiswa wajib saat perjalanan.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper kecil ----------

  Widget _label(String left, String right) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(right, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget icon,
    Widget? suffix,
  }) =>
      InputDecoration(
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
                  label: Text(s, style: const TextStyle(fontSize: 12)),
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
  final Color color;
  const _SectionCard({required this.child, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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
          Text(text,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          width: 32,
          height: 32,
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

/// Gambar peta sederhana (jalan + rute) sebagai pengganti peta asli.
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final route = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * .3),
        Offset(size.width, size.height * .55), road);
    canvas.drawLine(Offset(size.width * .3, 0),
        Offset(size.width * .45, size.height), road);
    canvas.drawLine(Offset(0, size.height * .8),
        Offset(size.width, size.height * .75), thin);
    canvas.drawLine(Offset(size.width * .75, 0),
        Offset(size.width * .8, size.height), thin);

    final path = Path()
      ..moveTo(size.width * .15, size.height * .7)
      ..quadraticBezierTo(
          size.width * .4, size.height * .2, size.width * .85, size.height * .4);
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}