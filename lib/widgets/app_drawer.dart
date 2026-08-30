import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/services/auth_service.dart';
import 'package:ev_charge_navigator/services/firestore_service.dart';
import 'package:ev_charge_navigator/models/car_model.dart';
import 'package:ev_charge_navigator/screens/price_comparison_page.dart';
import 'package:ev_charge_navigator/screens/admin/admin_dashboard.dart';

class AppDrawer extends StatefulWidget {
  final CarModel? primaryCar;
  final VoidCallback onDataChanged;

  const AppDrawer({
    super.key,
    this.primaryCar,
    required this.onDataChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _showPasswordFields = false;
  bool _passwordVerified = false;
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  String? _passError;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _resetPasswordState() {
    setState(() {
      _showPasswordFields = false;
      _passwordVerified = false;
      _passError = null;
      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    });
  }

  /// MANDATORY confirmation dialog before deleting an EV profile
  void _confirmDeleteCar(BuildContext context, CarModel car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete EV Profile?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${car.name}" from your vehicles?\nThis action requires confirmation.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              final firestore = FirestoreService();
              await firestore.deleteCar(auth.user!.uid, car.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                widget.onDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Vehicle profile deleted'),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppGradients.cardGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.electric_car,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      // Role Badge (ADMIN / CLIENT)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: auth.isAdmin ? AppColors.accent : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auth.isAdmin ? '👑 ADMIN' : '👤 CLIENT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.userName.isNotEmpty ? auth.userName : 'EV Driver',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.user?.email ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Panel Section (for admins)
                    if (auth.isAdmin) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'ADMIN PANEL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      _buildTile(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Control Center',
                        color: AppColors.primaryDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                          );
                        },
                      ),
                      const Divider(height: 16, indent: 16, endIndent: 16),
                    ],

                    // Services & Features Section
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'EV SERVICES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.price_change_outlined,
                      title: 'Price Comparison',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PriceComparisonPage()),
                        );
                      },
                    ),

                    const Divider(height: 16, indent: 16, endIndent: 16),

                    // My Vehicles Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'MY VEHICLES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.electric_car,
                          color: AppColors.primary, size: 24),
                      title: Text(
                        widget.primaryCar?.name ?? 'No vehicle selected',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: widget.primaryCar != null
                          ? Text(
                              '${widget.primaryCar!.connectorType} • ${widget.primaryCar!.batteryCapacity} kWh',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                            tooltip: 'Change Car',
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/car-selection').then((_) {
                                widget.onDataChanged();
                              });
                            },
                          ),
                          if (widget.primaryCar != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.negative),
                              tooltip: 'Delete Vehicle Profile',
                              onPressed: () => _confirmDeleteCar(context, widget.primaryCar!),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 16, indent: 16, endIndent: 16),

                    // Profile Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'PROFILE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.person_outline,
                      title: auth.userName.isNotEmpty ? auth.userName : 'Driver',
                      onTap: null,
                    ),
                    _buildTile(
                      icon: Icons.email_outlined,
                      title: auth.user?.email ?? 'No email',
                      onTap: null,
                    ),
                    _buildTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        setState(() {
                          _showPasswordFields = !_showPasswordFields;
                          if (!_showPasswordFields) _resetPasswordState();
                        });
                      },
                    ),

                    // Password fields (inline)
                    if (_showPasswordFields)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            if (!_passwordVerified) ...[
                              TextField(
                                controller: _oldPassController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Current Password',
                                  errorText: _passError,
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_oldPassController.text.isEmpty) {
                                      setState(() => _passError = 'Required');
                                      return;
                                    }
                                    final valid = await auth
                                        .verifyPassword(_oldPassController.text);
                                    setState(() {
                                      if (valid) {
                                        _passwordVerified = true;
                                        _passError = null;
                                      } else {
                                        _passError = 'Incorrect password';
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    textStyle: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  child: const Text('Verify'),
                                ),
                              ),
                            ],
                            if (_passwordVerified) ...[
                              TextField(
                                controller: _newPassController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _confirmPassController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  errorText: _passError,
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_newPassController.text.length < 6) {
                                      setState(() => _passError = 'Min 6 characters');
                                      return;
                                    }
                                    if (_newPassController.text !=
                                        _confirmPassController.text) {
                                      setState(
                                          () => _passError = 'Passwords don\'t match');
                                      return;
                                    }
                                    final ok = await auth
                                        .updatePassword(_newPassController.text);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ok
                                              ? 'Password updated'
                                              : auth.errorMessage ??
                                                  'Error updating'),
                                          backgroundColor: ok
                                              ? AppColors.positive
                                              : AppColors.negative,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    textStyle: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  child: const Text('Update'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Logout
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTile(
              icon: Icons.logout,
              title: 'Logout',
              color: AppColors.negative,
              onTap: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color ?? AppColors.textMuted, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textDark,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: AppColors.border, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
