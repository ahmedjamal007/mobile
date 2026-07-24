import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/api_exception.dart';
import '../../data/service_locator.dart';
import '../../models/station.dart';
import '../../models/train.dart';
import '../../widgets/async_view.dart';
import '../../widgets/info_row.dart';

/// Admin-only: publish a new schedule.
///
/// Maps to `POST /api/schedules/create/`, which is `IsAdminUser`. The screen is
/// only reachable from the Home tab's add button, itself shown only to staff —
/// but the server is the actual boundary, so a 403 is surfaced like any other
/// API error rather than being assumed impossible.
class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

/// Trains and stations are fetched together so the dropdowns populate in one
/// pass instead of two independent spinners.
class _FormOptions {
  final List<Train> trains;
  final List<Station> stations;
  const _FormOptions(this.trains, this.stations);
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _optionsKey = GlobalKey<AsyncViewState<_FormOptions>>();
  final _price = TextEditingController();
  final _seats = TextEditingController();

  Train? _train;
  Station? _from;
  Station? _to;
  DateTime? _departure;
  DateTime? _arrival;
  bool _submitting = false;

  @override
  void dispose() {
    _price.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<_FormOptions> _load() async {
    final results = await Future.wait([
      Services.I.catalog.trains(),
      Services.I.catalog.stations(),
    ]);
    return _FormOptions(
      results[0] as List<Train>,
      results[1] as List<Station>,
    );
  }

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    // Arrival defaults to just after departure so the common case is two taps.
    final seed = isDeparture
        ? (_departure ?? now.add(const Duration(days: 1)))
        : (_arrival ?? _departure?.add(const Duration(hours: 6)) ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null || !mounted) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isDeparture) {
        _departure = picked;
        // Keep arrival ahead of departure instead of silently staying invalid.
        if (_arrival != null && !_arrival!.isAfter(picked)) _arrival = null;
      } else {
        _arrival = picked;
      }
    });
  }

  String? _validateTimes() {
    if (_departure == null) return 'Pick a departure date and time.';
    if (_arrival == null) return 'Pick an arrival date and time.';
    if (!_arrival!.isAfter(_departure!)) {
      return 'Arrival must be after departure.';
    }
    if (!_departure!.isAfter(DateTime.now())) {
      return 'Departure must be in the future.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final timeError = _validateTimes();
    if (timeError != null) {
      Toast.error(context, timeError);
      return;
    }
    if (_from!.id == _to!.id) {
      Toast.error(context, 'Departure and arrival stations must differ.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await Services.I.catalog.createSchedule(
        trainId: _train!.id,
        departureStationId: _from!.id,
        arrivalStationId: _to!.id,
        departure: _departure!,
        arrival: _arrival!,
        ticketPrice: double.parse(_price.text.trim()),
        availableSeats: int.parse(_seats.text.trim()),
      );
      if (!mounted) return;
      Toast.success(context, 'Schedule published.');
      context.pop(true);
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add schedule')),
      body: AsyncView<_FormOptions>(
        key: _optionsKey,
        loader: _load,
        enableRefresh: false,
        builder: (context, options) {
          if (options.trains.isEmpty || options.stations.length < 2) {
            return _MissingPrerequisites(
              needsTrain: options.trains.isEmpty,
              needsStations: options.stations.length < 2,
              stationCount: options.stations.length,
              // Refetch so the newly created train/station appears.
              onAdded: () => _optionsKey.currentState?.reload(),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: 'TRAIN',
                  child: DropdownButtonFormField<Train>(
                    initialValue: _train,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Train'),
                    items: [
                      for (final train in options.trains)
                        DropdownMenuItem(
                          value: train,
                          child: Text(
                            train.capacity == null
                                ? train.label
                                : '${train.label} · ${train.capacity} seats',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (v) => v == null ? 'Select a train.' : null,
                    onChanged: (v) => setState(() => _train = v),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'ROUTE',
                  child: Column(
                    children: [
                      DropdownButtonFormField<Station>(
                        initialValue: _from,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'From station'),
                        items: [
                          for (final station in options.stations)
                            DropdownMenuItem(
                              value: station,
                              child: Text(station.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        validator: (v) =>
                            v == null ? 'Select a departure station.' : null,
                        onChanged: (v) => setState(() => _from = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Station>(
                        initialValue: _to,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'To station'),
                        items: [
                          for (final station in options.stations)
                            DropdownMenuItem(
                              value: station,
                              child: Text(station.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        validator: (v) {
                          if (v == null) return 'Select an arrival station.';
                          if (_from != null && v.id == _from!.id) {
                            return 'Must differ from the departure station.';
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() => _to = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'TIMING',
                  child: Column(
                    children: [
                      _DateTimeField(
                        label: 'Departure',
                        value: _departure,
                        onTap: () => _pickDateTime(isDeparture: true),
                      ),
                      const Divider(height: 1),
                      _DateTimeField(
                        label: 'Arrival',
                        value: _arrival,
                        onTap: () => _pickDateTime(isDeparture: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'PRICE & SEATS',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Ticket price',
                          prefixText: 'SDG ',
                        ),
                        validator: (v) {
                          final price = double.tryParse(v?.trim() ?? '');
                          if (price == null) return 'Enter a price.';
                          if (price <= 0) return 'Price must be above zero.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seats,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Available seats',
                        ),
                        validator: (v) {
                          final seats = int.tryParse(v?.trim() ?? '');
                          if (seats == null) return 'Enter a seat count.';
                          if (seats <= 0) return 'Must be at least one seat.';
                          // Mirrors the server-side capacity check so the admin
                          // finds out before submitting.
                          final capacity = _train?.capacity;
                          if (capacity != null && seats > capacity) {
                            return '${_train!.name} seats $capacity.';
                          }
                          return null;
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
                      : const Text('Publish schedule'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Passengers can reserve seats on this trip as soon as it is '
                  'published.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A schedule needs a train and two stations. Rather than dead-ending, offer
/// to create whichever is missing and reload the form afterwards.
class _MissingPrerequisites extends StatelessWidget {
  final bool needsTrain;
  final bool needsStations;
  final int stationCount;
  final VoidCallback onAdded;

  const _MissingPrerequisites({
    required this.needsTrain,
    required this.needsStations,
    required this.stationCount,
    required this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_add,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Almost there',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'A schedule needs one train and two stations. '
            '${needsTrain ? 'No trains yet' : 'Trains ready'}; '
            '$stationCount station(s) so far.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (needsTrain)
            ElevatedButton.icon(
              onPressed: () async {
                if (await context.push<bool>('/staff/trains/new') == true) {
                  onAdded();
                }
              },
              icon: const Icon(Icons.train_outlined),
              label: const Text('Add a train'),
            ),
          if (needsTrain && needsStations) const SizedBox(height: 12),
          if (needsStations)
            OutlinedButton.icon(
              onPressed: () async {
                if (await context.push<bool>('/staff/stations/new') == true) {
                  onAdded();
                }
              },
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Add a station'),
            ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.schedule,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Text(
              value == null ? 'Select' : Formatters.dateTime(value),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value == null ? AppColors.primary : null,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
