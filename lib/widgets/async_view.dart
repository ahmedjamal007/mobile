import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import 'state_views.dart';

/// Reusable load-once view that handles the loading / error / data states and
/// supports pull-to-refresh. Keeps every list screen from re-implementing the
/// same FutureBuilder boilerplate.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data) builder;
  final bool enableRefresh;

  const AsyncView({
    super.key,
    required this.loader,
    required this.builder,
    this.enableRefresh = true,
  });

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> reload() async {
    setState(() => _future = widget.loader());
    await _future.catchError((_) => null as T);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final message = error is ApiException
              ? error.message
              : 'Something went wrong. Please try again.';
          return ErrorView(message: message, onRetry: reload);
        }
        final content = widget.builder(context, snapshot.data as T);
        if (!widget.enableRefresh) return content;
        return RefreshIndicator(onRefresh: reload, child: content);
      },
    );
  }
}
