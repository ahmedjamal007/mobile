import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_provider.dart';
import '../screens/admin/add_schedule_screen.dart';
import '../screens/admin/add_station_screen.dart';
import '../screens/admin/add_train_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/payments/payment_detail_screen.dart';
import '../screens/payments/payment_upload_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/reservations/reservation_detail_screen.dart';
import '../screens/reservations/reserve_screen.dart';
import '../screens/schedules/schedule_detail_screen.dart';
import '../screens/staff/review_queue_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';

/// Central navigation. Redirects between the auth flow and the app shell based
/// on [AuthProvider.status]; individual feature pages are pushed on top.
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onAuth = loc == '/login' || loc == '/register';

      if (status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        return onAuth ? null : '/login';
      }
      // Authenticated: keep users out of splash/auth pages.
      if (onSplash || onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(
        path: '/schedule/:id',
        builder: (_, s) => ScheduleDetailScreen(scheduleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reserve/:id',
        builder: (_, s) => ReserveScreen(scheduleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (_, s) =>
            ReservationDetailScreen(reservationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pay/:reservationId',
        builder: (_, s) => PaymentUploadScreen(
            reservationId: s.pathParameters['reservationId']!),
      ),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
      GoRoute(
        path: '/payment/:id',
        builder: (_, s) =>
            PaymentDetailScreen(paymentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (_, s) => TicketDetailScreen(ticketId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/staff/review',
        builder: (_, __) => const ReviewQueueScreen(),
      ),
      GoRoute(
        path: '/staff/schedules/new',
        builder: (_, __) => const AddScheduleScreen(),
      ),
      GoRoute(
        path: '/staff/trains/new',
        builder: (_, __) => const AddTrainScreen(),
      ),
      GoRoute(
        path: '/staff/stations/new',
        builder: (_, __) => const AddStationScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
