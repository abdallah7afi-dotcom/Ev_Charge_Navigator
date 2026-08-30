import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';

class PriceComparisonPage extends StatefulWidget {
  const PriceComparisonPage({super.key});

  @override
  State<PriceComparisonPage> createState() => _PriceComparisonPageState();
}

class _PriceComparisonPageState extends State<PriceComparisonPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<StationModel> _stations = [];
  bool _loading = true;
  String _selectedProvider = 'All';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    try {
      final list = await _firestoreService.getAllStations();
      // Sort by price per kWh (cheapest first)
      list.sort((a, b) => a.pricePerKwh.compareTo(b.pricePerKwh));
      if (mounted) {
        setState(() {
          _stations = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawProviders = ['All', 'EVIQ', 'Electromin', ..._stations.map((s) => s.provider)];
    final providers = rawProviders.toSet().toList();

    final filtered = _stations.where((s) {
      if (_selectedProvider == 'All') return true;
      return s.provider.toLowerCase().contains(_selectedProvider.toLowerCase()) ||
          s.name.toLowerCase().contains(_selectedProvider.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Charging Price Comparison',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: providers.map((prov) {
                      final isSelected = prov == _selectedProvider;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(prov),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedProvider = prov);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No stations found',
                            style: GoogleFonts.inter(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (ctx, idx) {
                            final st = filtered[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryLight
                                          .withValues(alpha: 0.15),
                                      child: const Icon(Icons.bolt,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            st.name,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${st.provider} • ${st.power.toStringAsFixed(0)} kW • ${st.connectorType}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${st.pricePerKwh.toStringAsFixed(2)} SAR',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        Text(
                                          'per kWh',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
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
