import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/service_locator.dart';
import '../../models/schedule.dart';
import '../../state/auth_provider.dart';
import '../admin/admin_add_sheet.dart';
import '../../widgets/async_view.dart';
import '../../widgets/state_views.dart';
import 'widgets/schedule_card.dart';

/// Home tab: browse upcoming schedules with a client-side search box.
///
/// The backend list endpoint returns *all* schedules with no query-param
/// filtering yet, so filtering happens here in the app (per the requirements).
///
/// Staff and admins also get an "add schedule" button here; creating one is
/// admin-only server-side.
class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _key = GlobalKey<AsyncViewState<List<Schedule>>>();
  String _query = '';

  List<Schedule> _filter(List<Schedule> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((s) =>
            s.departureStation.toLowerCase().contains(q) ||
            s.arrivalStation.toLowerCase().contains(q) ||
            s.trainName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openAdminAdd() async {
    final created = await showAdminAddSheet(context);
    // Only refetch when something was actually created.
    if (created && mounted) _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: _openAdminAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: _buildList(),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search station or train…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: AsyncView<List<Schedule>>(
            key: _key,
            loader: () => Services.I.catalog.schedules(),
            builder: (context, all) {
              final filtered = _filter(all);
              if (all.isEmpty) {
                return const EmptyView(
                  icon: Icons.train_outlined,
                  title: 'No schedules yet',
                  subtitle: 'Please check back later for upcoming trains.',
                );
              }
              if (filtered.isEmpty) {
                return EmptyView(
                  icon: Icons.search_off,
                  title: 'No matches',
                  subtitle: 'No schedules match "$_query".',
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  return ScheduleCard(
                    schedule: s,
                    onTap: () => context.push('/schedule/${s.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
