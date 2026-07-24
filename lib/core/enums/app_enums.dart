import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// User role as returned by the backend on login and on the profile endpoint.
/// Derived server-side from Django's `is_superuser` / `is_staff`.
enum UserRole { admin, staff, passenger }

extension UserRoleX on UserRole {
  static UserRole fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'STAFF':
        return UserRole.staff;
      default:
        return UserRole.passenger;
    }
  }

  String get apiValue => switch (this) {
        UserRole.admin => 'ADMIN',
        UserRole.staff => 'STAFF',
        UserRole.passenger => 'PASSENGER',
      };

  /// Staff and admin both get the payment-review queue.
  bool get canReviewPayments =>
      this == UserRole.staff || this == UserRole.admin;
}

/// Reservation lifecycle. Mirrors the backend status strings.
enum ReservationStatus {
  pendingPayment,
  paymentSubmitted,
  confirmed,
  cancelled,
  unknown,
}

extension ReservationStatusX on ReservationStatus {
  static ReservationStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING_PAYMENT':
        return ReservationStatus.pendingPayment;
      case 'PAYMENT_SUBMITTED':
        return ReservationStatus.paymentSubmitted;
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.unknown;
    }
  }

  String get label => switch (this) {
        ReservationStatus.pendingPayment => 'Pending Payment',
        ReservationStatus.paymentSubmitted => 'Payment Submitted',
        ReservationStatus.confirmed => 'Confirmed',
        ReservationStatus.cancelled => 'Cancelled',
        ReservationStatus.unknown => 'Unknown',
      };

  Color get color => switch (this) {
        ReservationStatus.pendingPayment => AppColors.warning,
        ReservationStatus.paymentSubmitted => AppColors.info,
        ReservationStatus.confirmed => AppColors.success,
        ReservationStatus.cancelled => AppColors.error,
        ReservationStatus.unknown => AppColors.textSecondary,
      };

  bool get canPay => this == ReservationStatus.pendingPayment;
}

/// Payment review status.
enum PaymentStatus { pending, approved, rejected, unknown }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return PaymentStatus.pending;
      case 'APPROVED':
        return PaymentStatus.approved;
      case 'REJECTED':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get apiValue => switch (this) {
        PaymentStatus.pending => 'PENDING',
        PaymentStatus.approved => 'APPROVED',
        PaymentStatus.rejected => 'REJECTED',
        PaymentStatus.unknown => 'UNKNOWN',
      };

  String get label => switch (this) {
        PaymentStatus.pending => 'Pending Review',
        PaymentStatus.approved => 'Approved',
        PaymentStatus.rejected => 'Rejected',
        PaymentStatus.unknown => 'Unknown',
      };

  Color get color => switch (this) {
        PaymentStatus.pending => AppColors.warning,
        PaymentStatus.approved => AppColors.success,
        PaymentStatus.rejected => AppColors.error,
        PaymentStatus.unknown => AppColors.textSecondary,
      };
}

/// Notification categories the backend emits.
enum NotificationType { reservation, payment, ticket, general }

extension NotificationTypeX on NotificationType {
  static NotificationType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'RESERVATION':
        return NotificationType.reservation;
      case 'PAYMENT':
        return NotificationType.payment;
      case 'TICKET':
        return NotificationType.ticket;
      default:
        return NotificationType.general;
    }
  }

  IconData get icon => switch (this) {
        NotificationType.reservation => Icons.event_seat_outlined,
        NotificationType.payment => Icons.receipt_long_outlined,
        NotificationType.ticket => Icons.confirmation_number_outlined,
        NotificationType.general => Icons.notifications_outlined,
      };

  Color get color => switch (this) {
        NotificationType.reservation => AppColors.info,
        NotificationType.payment => AppColors.warning,
        NotificationType.ticket => AppColors.success,
        NotificationType.general => AppColors.primary,
      };
}

/// Mirrors `schedules.models.ScheduleStatus` on the backend.
enum ScheduleStatus { available, completed, cancelled, unknown }

extension ScheduleStatusX on ScheduleStatus {
  static ScheduleStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'AVAILABLE':
        return ScheduleStatus.available;
      case 'COMPLETED':
        return ScheduleStatus.completed;
      case 'CANCELLED':
        return ScheduleStatus.cancelled;
      default:
        return ScheduleStatus.unknown;
    }
  }

  String get label => switch (this) {
        ScheduleStatus.available => 'Available',
        ScheduleStatus.completed => 'Completed',
        ScheduleStatus.cancelled => 'Cancelled',
        ScheduleStatus.unknown => 'Unknown',
      };

  Color get color => switch (this) {
        ScheduleStatus.available => AppColors.success,
        ScheduleStatus.completed => AppColors.textSecondary,
        ScheduleStatus.cancelled => AppColors.error,
        ScheduleStatus.unknown => AppColors.textSecondary,
      };

  bool get isBookable => this == ScheduleStatus.available;
}
