import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:yb_staff_app/core/widgets/app_toast.dart';

class ConnectivityObserver extends StatefulWidget {
  const ConnectivityObserver({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityObserver> createState() => _ConnectivityObserverState();
}

class _ConnectivityObserverState extends State<ConnectivityObserver> {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool? _wasOnline; // null = not yet determined (skip first event)

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (_wasOnline == null) {
      // First event — record state silently, no toast
      _wasOnline = isOnline;
      return;
    }

    if (!isOnline && _wasOnline == true) {
      _wasOnline = false;
      _showToast('Tidak ada koneksi internet', ToastType.error);
    } else if (isOnline && _wasOnline == false) {
      _wasOnline = true;
      _showToast('Koneksi internet terhubung kembali', ToastType.success);
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    AppToast.show(context, message,
        type: type, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
