import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../widgets/info_row.dart';

/// Admin-only: register a train that schedules can then be built on.
///
/// Maps to `POST /api/trains/` — the same path the list uses, where only the
/// POST is admin-gated.
class AddTrainScreen extends StatefulWidget {
  const AddTrainScreen({super.key});

  @override
  State<AddTrainScreen> createState() => _AddTrainScreenState();
}

const _trainTypes = {
  'PASSENGER': 'Passenger',
  'EXPRESS': 'Express',
  'FREIGHT': 'Freight',
};

class _AddTrainScreenState extends State<AddTrainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _capacity = TextEditingController();

  String _type = 'PASSENGER';
  bool _submitting = false;

  /// Field errors returned by the API (e.g. a duplicate train number), shown
  /// against the offending input rather than only in a toast.
  Map<String, String> _apiErrors = const {};

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final train = await Services.I.catalog.createTrain(
        trainNumber: _number.text.trim(),
        name: _name.text.trim(),
        capacity: int.parse(_capacity.text.trim()),
        trainType: _type,
      );
      if (!mounted) return;
      Toast.success(context, '${train.name} added.');
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiErrors = e.fieldErrors);
      // Re-run validation so the API's message lands on the right field.
      _formKey.currentState!.validate();
      if (e.fieldErrors.isEmpty) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add train')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'TRAIN',
              child: Column(
                children: [
                  TextFormField(
                    controller: _number,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Train number',
                      hintText: 'e.g. T-100',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) {
                        return 'Enter a train number.';
                      }
                      return _apiErrors['train_number'];
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Nile Express',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Enter a name.';
                      return _apiErrors['name'];
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'DETAILS',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      for (final entry in _trainTypes.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'PASSENGER'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Total seats on this train',
                    ),
                    validator: (v) {
                      final capacity = int.tryParse(v?.trim() ?? '');
                      if (capacity == null) return 'Enter a capacity.';
                      if (capacity < 1) return 'Must be at least one seat.';
                      return _apiErrors['capacity'];
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
                  : const Text('Add train'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Capacity caps how many seats a schedule on this train can '
              'offer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
