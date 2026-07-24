import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../widgets/info_row.dart';

/// Admin-only: register a station that routes can run between.
///
/// Maps to `POST /api/stations/create/`. Both name and code are unique
/// server-side, so duplicates come back as field errors.
class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();

  bool _submitting = false;
  Map<String, String> _apiErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final station = await Services.I.catalog.createStation(
        name: _name.text.trim(),
        code: _code.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      Toast.success(context, '${station.name} added.');
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiErrors = e.fieldErrors);
      _formKey.currentState!.validate();
      if (e.fieldErrors.isEmpty) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add station')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'STATION',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Khartoum',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Enter a name.';
                      return _apiErrors['name'];
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      hintText: 'e.g. KRT',
                    ),
                    validator: (v) {
                      final code = (v ?? '').trim();
                      if (code.isEmpty) return 'Enter a short code.';
                      if (code.length < 2) {
                        return 'Use at least two characters.';
                      }
                      return _apiErrors['code'];
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Add station'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Name and code must both be unique. The code is stored in '
              'uppercase.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
