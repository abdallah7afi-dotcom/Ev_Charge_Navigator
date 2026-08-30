import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';

class BatteryDialog {
  static Future<double?> show(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Enter Battery Level',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Battery Level',
                  hintText: 'e.g. 45',
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.battery_std,
                      color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a value between 1 and 100',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value == null || value < 1 || value > 100) {
                    setState(() {
                      errorText = 'Please enter a valid value (1-100)';
                    });
                    return;
                  }
                  Navigator.pop(ctx, value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Find Stations',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
