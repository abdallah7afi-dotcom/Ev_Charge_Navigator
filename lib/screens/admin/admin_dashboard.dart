import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/models/car_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Page-level authorization guard: even if a non-admin user reaches
    // this route directly (e.g. Navigator.pushNamed('/admin')), the
    // admin tabs and data are never built for them. Hiding the drawer
    // button alone is not sufficient authorization.
    final isAdmin = context.watch<AuthService>().isAdmin;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'You do not have permission to view this page.',
              style: GoogleFonts.inter(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Admin Control Panel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.ev_station), text: 'Stations'),
            Tab(icon: Icon(Icons.people_alt), text: 'Users'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AdminStationManagementTab(firestoreService: _firestoreService),
          _AdminUserManagementTab(firestoreService: _firestoreService),
          _AdminReportsTab(firestoreService: _firestoreService),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 1. Station Management Tab
// ──────────────────────────────────────────────────────────────
class _AdminStationManagementTab extends StatefulWidget {
  final FirestoreService firestoreService;

  const _AdminStationManagementTab({required this.firestoreService});

  @override
  State<_AdminStationManagementTab> createState() =>
      __AdminStationManagementTabState();
}

class __AdminStationManagementTabState
    extends State<_AdminStationManagementTab> {
  List<StationModel> _stations = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    try {
      final list = await widget.firestoreService.getAllStations();
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

  void _showStationFormDialog([StationModel? station]) {
    final nameCtrl = TextEditingController(text: station?.name ?? '');
    final addressCtrl = TextEditingController(text: station?.address ?? '');
    final latCtrl = TextEditingController(
      text: station != null ? station.latitude.toString() : '24.7136',
    );
    final lngCtrl = TextEditingController(
      text: station != null ? station.longitude.toString() : '46.6753',
    );
    final connectorCtrl = TextEditingController(
      text: station?.connectorType ?? 'CCS2',
    );
    final powerCtrl = TextEditingController(
      text: station != null ? station.power.toString() : '150',
    );
    final feeCtrl = TextEditingController(text: station?.fee ?? '1.20 SAR/kWh');
    final providerCtrl = TextEditingController(
      text: station?.provider ?? 'EVIQ',
    );
    String selectedStatus = station?.status ?? 'Available';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          station == null ? 'Add New Station' : 'Edit Station',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Station Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: connectorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Connector Type',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: powerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Power (kW)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fee / Price',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: providerCtrl,
                      decoration: const InputDecoration(labelText: 'Provider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Available', 'Occupied', 'Maintenance', 'Offline']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedStatus = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              final newStation = StationModel(
                id: station?.id ?? '',
                name: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                latitude: double.tryParse(latCtrl.text) ?? 24.7136,
                longitude: double.tryParse(lngCtrl.text) ?? 46.6753,
                connectorType: connectorCtrl.text.trim(),
                power: double.tryParse(powerCtrl.text) ?? 150.0,
                fee: feeCtrl.text.trim(),
                rating: station?.rating ?? 4.5,
                status: selectedStatus,
                provider: providerCtrl.text.trim(),
              );

              if (station == null) {
                await widget.firestoreService.addStation(newStation);
              } else {
                await widget.firestoreService.updateStation(newStation);
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                _loadStations();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      station == null
                          ? '✅ Station added successfully'
                          : '✅ Station updated successfully',
                    ),
                    backgroundColor: AppColors.positive,
                  ),
                );
              }
            },
            child: Text(station == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  /// MANDATORY Confirmation Dialog before station deletion
  void _confirmDeleteStation(StationModel station) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.negative,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Station?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${station.name}"?\nThis action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.firestoreService.deleteStation(station.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _loadStations();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Station deleted permanently'),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _stations
        .where(
          (s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.provider.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      children: [
        // Header bar with search & add button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search stations...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showStationFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(90, 44),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    'No stations found',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (ctx, idx) {
                    final st = filtered[idx];
                    Color statusColor = AppColors.positive;
                    if (st.status == 'Occupied') statusColor = Colors.orange;
                    if (st.status == 'Maintenance') statusColor = Colors.purple;
                    if (st.status == 'Offline')
                      statusColor = AppColors.negative;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.15),
                          child: Icon(Icons.ev_station, color: statusColor),
                        ),
                        title: Text(
                          st.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${st.provider} • ${st.power.toStringAsFixed(0)} kW • ${st.connectorType}\n${st.fee}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                st.status,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              iconSize: 18,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showStationFormDialog(st),
                            ),
                            IconButton(
                              iconSize: 18,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.negative,
                              ),
                              onPressed: () => _confirmDeleteStation(st),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 2. User Management Tab
// ──────────────────────────────────────────────────────────────
class _AdminUserManagementTab extends StatelessWidget {
  final FirestoreService firestoreService;

  const _AdminUserManagementTab({required this.firestoreService});

  void _confirmDeleteUser(
    BuildContext context,
    String uid,
    String nameOrEmail,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.negative,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete User Account?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete account for "$nameOrEmail"?\nThis action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestoreService.deleteUserAccount(uid);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ User account deleted'),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleUserRole(String uid, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'client' : 'admin';
    await firestoreService.updateUserRole(uid, newRole);
  }

  void _confirmDeleteCar(BuildContext context, String uid, CarModel car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Vehicle Profile?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${car.name}" for this user?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestoreService.deleteCar(uid, car.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Vehicle profile deleted'),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditCarDialog(BuildContext context, String uid, CarModel car) {
    final nameCtrl = TextEditingController(text: car.name);
    final connectorCtrl = TextEditingController(text: car.connectorType);
    final batteryCtrl = TextEditingController(
      text: car.batteryCapacity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit EV Vehicle Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Car Name / Model'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: connectorCtrl,
              decoration: const InputDecoration(
                labelText: 'Connector Type (e.g. CCS2, Type 2)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: batteryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Battery Capacity (kWh)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              final updatedCar = CarModel(
                id: car.id,
                name: newName,
                connectorType: connectorCtrl.text.trim(),
                batteryCapacity:
                    double.tryParse(batteryCtrl.text.trim()) ??
                    car.batteryCapacity,
              );
              await firestoreService.saveCar(uid, updatedCar);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Vehicle profile updated'),
                    backgroundColor: AppColors.positive,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading users: ${snapshot.error}',
              style: GoogleFonts.inter(color: AppColors.negative),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (ctx, idx) {
            final userDoc = docs[idx];
            final data = userDoc.data() as Map<String, dynamic>? ?? {};
            final uid = userDoc.id;
            final name = data['name'] ?? 'User';
            final email = data['email'] ?? 'No Email';
            final role = data['role'] ?? 'client';
            final isAdmin = role == 'admin';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin
                      ? AppColors.accent
                      : AppColors.primaryLight,
                  child: Icon(
                    isAdmin ? Icons.shield : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  name.isNotEmpty ? name : email,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        isAdmin ? Icons.star : Icons.person_outline,
                        size: 14,
                      ),
                      label: Text(
                        isAdmin ? 'ADMIN' : 'CLIENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: isAdmin
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                      onPressed: () => _toggleUserRole(uid, role),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.negative,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteUser(
                        context,
                        uid,
                        name.isNotEmpty ? name : email,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGISTERED EV VEHICLES',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('cars')
                              .snapshots(),
                          builder: (context, carSnap) {
                            if (carSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }

                            final carDocs = carSnap.data?.docs ?? [];

                            if (carDocs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No vehicle profiles registered for this user.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: carDocs.map((cDoc) {
                                final cData =
                                    cDoc.data() as Map<String, dynamic>;
                                final car = CarModel.fromMap(cData, cDoc.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.electric_car,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    title: Text(
                                      car.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${car.connectorType} • ${car.batteryCapacity.toStringAsFixed(0)} kWh',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 18,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _showEditCarDialog(
                                            context,
                                            uid,
                                            car,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          iconSize: 18,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.negative,
                                          ),
                                          onPressed: () => _confirmDeleteCar(
                                            context,
                                            uid,
                                            car,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 3. System Reports Tab
// ──────────────────────────────────────────────────────────────
class _AdminReportsTab extends StatefulWidget {
  final FirestoreService firestoreService;

  const _AdminReportsTab({required this.firestoreService});

  @override
  State<_AdminReportsTab> createState() => __AdminReportsTabState();
}

class __AdminReportsTabState extends State<_AdminReportsTab> {
  Map<String, dynamic>? _reports;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final data = await widget.firestoreService.getSystemReports();
    if (mounted) {
      setState(() {
        _reports = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health & Performance',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildReportCard(
                'Total Users',
                '${_reports?['totalUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildReportCard(
                'Total Stations',
                '${_reports?['totalStations'] ?? 0}',
                Icons.ev_station,
                AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildReportCard(
                'System Uptime',
                '${_reports?['uptime'] ?? "99.9%"}',
                Icons.verified,
                AppColors.positive,
              ),
              const SizedBox(width: 12),
              _buildReportCard(
                'Avg Latency',
                '${_reports?['avgResponseTimeMs'] ?? 240} ms',
                Icons.speed,
                AppColors.accent,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Station Availability Status Breakdown',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusRow(
                    'Available',
                    _reports?['availableStations'] ?? 0,
                    AppColors.positive,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    'Occupied',
                    _reports?['occupiedStations'] ?? 0,
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    'Maintenance',
                    _reports?['maintenanceStations'] ?? 0,
                    Colors.purple,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    'Offline',
                    _reports?['offlineStations'] ?? 0,
                    AppColors.negative,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh System Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
        Text('$count', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
