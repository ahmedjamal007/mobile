import 'package:flutter_test/flutter_test.dart';
import 'package:srrs_mobile/core/enums/app_enums.dart';
import 'package:srrs_mobile/models/app_notification.dart';
import 'package:srrs_mobile/models/auth_tokens.dart';
import 'package:srrs_mobile/models/payment.dart';
import 'package:srrs_mobile/models/reservation.dart';
import 'package:srrs_mobile/models/schedule.dart';
import 'package:srrs_mobile/models/station.dart';
import 'package:srrs_mobile/models/ticket.dart';
import 'package:srrs_mobile/models/user.dart';

/// Fixtures below are verbatim responses captured from the Django API, so a
/// serializer change on the backend shows up here as a failing test rather
/// than as a silently blank field on a screen.
void main() {
  group('Schedule', () {
    final json = <String, dynamic>{
      'id': '0ab16cca-8ef6-4ac0-b1e4-430a9ff8d2b3',
      'train': 'f561da75-7844-485b-a362-18ad4070246a',
      'train_name': 'Nile Express',
      'departure_station': '891a9d89-7c1c-4064-8556-475ace7d6fd2',
      'departure_station_name': 'Khartoum',
      'arrival_station': 'c7b68918-4d00-4943-ad6a-5289eb2053d8',
      'arrival_station_name': 'Atbara',
      'departure_datetime': '2026-07-24T01:09:49.550403Z',
      'arrival_datetime': '2026-07-24T07:09:49.550414Z',
      'ticket_price': '150.00',
      'available_seats': 50,
      'status': 'AVAILABLE',
    };

    test('parses the fields the schedule card renders', () {
      final schedule = Schedule.fromJson(json);

      expect(schedule.trainName, 'Nile Express');
      expect(schedule.departureStation, 'Khartoum');
      expect(schedule.arrivalStation, 'Atbara');
      // ticket_price arrives as a DecimalField string, not a number.
      expect(schedule.ticketPrice, 150.00);
      expect(schedule.seatsAvailable, 50);
      expect(schedule.departureTime, isNotNull);
      expect(schedule.arrivalTime, isNotNull);
    });

    test('AVAILABLE is bookable and shows a 6h trip', () {
      final schedule = Schedule.fromJson(json);

      expect(schedule.status, ScheduleStatus.available);
      expect(schedule.status.isBookable, isTrue);
      expect(schedule.durationLabel, '6h 0m');
    });

    test('COMPLETED and CANCELLED are not bookable', () {
      expect(
        Schedule.fromJson({...json, 'status': 'COMPLETED'}).status.isBookable,
        isFalse,
      );
      expect(
        Schedule.fromJson({...json, 'status': 'CANCELLED'}).status.isBookable,
        isFalse,
      );
    });
  });

  group('Reservation', () {
    final json = <String, dynamic>{
      'id': '8b3f33bc-5bd5-4766-b7ab-549d60991b62',
      'schedule': '0ab16cca-8ef6-4ac0-b1e4-430a9ff8d2b3',
      'train_name': 'Nile Express',
      'departure_station': 'Khartoum',
      'arrival_station': 'Atbara',
      'departure_datetime': '2026-07-24T01:09:49.550403Z',
      'seats': 2,
      'total_price': '300.00',
      'status': 'PENDING_PAYMENT',
      'created_at': '2026-07-21T01:09:49.683374Z',
    };

    test('parses the flattened trip snapshot', () {
      final reservation = Reservation.fromJson(json);

      expect(reservation.scheduleId, '0ab16cca-8ef6-4ac0-b1e4-430a9ff8d2b3');
      expect(reservation.trainName, 'Nile Express');
      expect(reservation.departureStation, 'Khartoum');
      expect(reservation.arrivalStation, 'Atbara');
      expect(reservation.seats, 2);
      expect(reservation.totalPrice, 300.00);
      expect(reservation.departureTime, isNotNull);
      expect(reservation.createdAt, isNotNull);
    });

    test('PENDING_PAYMENT offers the pay action', () {
      final reservation = Reservation.fromJson(json);

      expect(reservation.status, ReservationStatus.pendingPayment);
      expect(reservation.status.canPay, isTrue);
    });

    test('every backend status maps to a known value', () {
      for (final entry in {
        'PENDING_PAYMENT': ReservationStatus.pendingPayment,
        'PAYMENT_SUBMITTED': ReservationStatus.paymentSubmitted,
        'CONFIRMED': ReservationStatus.confirmed,
        'CANCELLED': ReservationStatus.cancelled,
      }.entries) {
        expect(
          Reservation.fromJson({...json, 'status': entry.key}).status,
          entry.value,
        );
      }
    });
  });

  group('Payment', () {
    final json = <String, dynamic>{
      'id': 'bd8e6b64-06e0-4e63-bfd7-b8e87d3a561d',
      'reservation': '8b3f33bc-5bd5-4766-b7ab-549d60991b62',
      'reservation_info': {
        'id': '8b3f33bc-5bd5-4766-b7ab-549d60991b62',
        'train': 'Nile Express',
        'departure_station': 'Khartoum',
        'arrival_station': 'Atbara',
        'departure_datetime': '2026-07-24T01:09:49.550403Z',
        'total_price': '300.00',
        'seats': 2,
        'passenger_name': 'Amal Hassan',
      },
      'receipt':
          'http://testserver/media/payments/8b3f33bc/receipt.jpg',
      'status': 'PENDING',
      'admin_note': null,
      'reviewed_at': null,
      'created_at': '2026-07-21T01:09:49.708367Z',
    };

    test('parses the staff-queue snapshot', () {
      final payment = Payment.fromJson(json);

      expect(payment.trainName, 'Nile Express');
      expect(payment.departureStation, 'Khartoum');
      expect(payment.arrivalStation, 'Atbara');
      expect(payment.seats, 2);
      expect(payment.totalPrice, 300.00);
      expect(payment.passengerName, 'Amal Hassan');
      expect(payment.departureTime, isNotNull);
      expect(payment.status, PaymentStatus.pending);
    });

    test('keeps an already-absolute receipt URL as-is', () {
      expect(
        Payment.fromJson(json).receiptUrl,
        'http://testserver/media/payments/8b3f33bc/receipt.jpg',
      );
    });

    test('resolves a relative receipt path to an absolute URL', () {
      final payment = Payment.fromJson({
        ...json,
        'receipt': '/media/payments/8b3f33bc/receipt.jpg',
      });

      // ReceiptImage only treats http(s) strings as remote, so a relative
      // path would otherwise render as "no receipt".
      expect(payment.receiptUrl, startsWith('http'));
      expect(payment.receiptUrl, endsWith('/media/payments/8b3f33bc/receipt.jpg'));
    });

    test('carries the rejection reason', () {
      final payment = Payment.fromJson({
        ...json,
        'status': 'REJECTED',
        'admin_note': 'Receipt is blurry.',
      });

      expect(payment.isRejected, isTrue);
      expect(payment.adminNote, 'Receipt is blurry.');
    });
  });

  group('Ticket', () {
    final json = <String, dynamic>{
      'id': '617edd8a-3147-4ea6-a767-915b3969695d',
      'ticket_number': 'SRC-2026-000001',
      'reservation_id': '8b3f33bc-5bd5-4766-b7ab-549d60991b62',
      'passenger': 'Amal Hassan',
      'username': 'amal',
      'train': 'Nile Express',
      'departure_station': 'Khartoum',
      'arrival_station': 'Atbara',
      'departure_datetime': '2026-07-24T01:09:49.550403Z',
      'arrival_datetime': '2026-07-24T07:09:49.550414Z',
      'seats': 2,
      'total_price': '300.00',
      'status': 'ACTIVE',
    };

    test('parses the ticket face', () {
      final ticket = Ticket.fromJson(json);

      expect(ticket.ticketNumber, 'SRC-2026-000001');
      expect(ticket.passengerName, 'Amal Hassan');
      expect(ticket.trainName, 'Nile Express');
      expect(ticket.departureStation, 'Khartoum');
      expect(ticket.arrivalStation, 'Atbara');
      expect(ticket.seats, 2);
      expect(ticket.totalPrice, 300.00);
      expect(ticket.departureTime, isNotNull);
      expect(ticket.arrivalTime, isNotNull);
    });

    test('ACTIVE is valid, USED and CANCELLED are not', () {
      expect(Ticket.fromJson(json).isValid, isTrue);
      expect(Ticket.fromJson({...json, 'status': 'USED'}).isValid, isFalse);
      expect(Ticket.fromJson({...json, 'status': 'CANCELLED'}).isValid, isFalse);
    });

    test('falls back to username when the user has no full name', () {
      // get_full_name() returns "" for users with no first/last name.
      final ticket = Ticket.fromJson({...json, 'passenger': ''});

      expect(ticket.passengerName, 'amal');
    });
  });

  group('User', () {
    final json = <String, dynamic>{
      'id': 1,
      'username': 'amal',
      'first_name': 'Amal',
      'last_name': 'Hassan',
      'email': 'amal@example.com',
      'is_staff': false,
      'is_superuser': false,
      'role': 'PASSENGER',
      'profile': {
        'phone_number': '+249900000001',
        'national_id': 'NID-0001',
        'gender': 'FEMALE',
        'profile_photo': null,
        'national_id_photo': null,
        'is_verified': false,
      },
    };

    test('reads details out of the nested profile block', () {
      final user = User.fromJson(json);

      // id is an int on the wire, unlike every other model's UUID string.
      expect(user.id, '1');
      expect(user.fullName, 'Amal Hassan');
      expect(user.phoneNumber, '+249900000001');
      expect(user.nationalId, 'NID-0001');
      expect(user.gender, 'FEMALE');
      expect(user.isVerified, isFalse);
      expect(user.role, UserRole.passenger);
      expect(user.role.canReviewPayments, isFalse);
    });

    test('staff and admin unlock the review queue', () {
      expect(
        User.fromJson({...json, 'role': 'STAFF'}).role.canReviewPayments,
        isTrue,
      );
      expect(
        User.fromJson({...json, 'role': 'ADMIN'}).role.canReviewPayments,
        isTrue,
      );
    });

    test('an explicit role argument wins over the serialized one', () {
      // Login sends role at the top level, beside the user object.
      expect(User.fromJson(json, role: 'ADMIN').role, UserRole.admin);
    });

    test('survives a profile that has not been filled in', () {
      final user = User.fromJson({...json}..remove('profile'));

      expect(user.username, 'amal');
      expect(user.phoneNumber, isNull);
    });
  });

  group('AuthTokens', () {
    test('reads the nested tokens block from login', () {
      final tokens = AuthTokens.fromJson({
        'user': {'username': 'amal'},
        'role': 'PASSENGER',
        'tokens': {'refresh': 'refresh-jwt', 'access': 'access-jwt'},
      });

      expect(tokens.access, 'access-jwt');
      expect(tokens.refresh, 'refresh-jwt');
    });

    test('also reads a flat pair, as /api/token/ returns', () {
      final tokens =
          AuthTokens.fromJson({'refresh': 'refresh-jwt', 'access': 'access-jwt'});

      expect(tokens.access, 'access-jwt');
      expect(tokens.refresh, 'refresh-jwt');
    });
  });

  group('AppNotification', () {
    final json = <String, dynamic>{
      'id': '07b95cd4-ddf2-4526-ba0b-bc35fe51a134',
      'notification_type': 'TICKET',
      'title': 'Ticket issued',
      'message': 'Ticket SRC-2026-000001 for Khartoum → Atbara has been issued.',
      'is_read': false,
      'created_at': '2026-07-21T01:09:49.739583Z',
    };

    test('parses an inbox row', () {
      final notification = AppNotification.fromJson(json);

      expect(notification.type, NotificationType.ticket);
      expect(notification.title, 'Ticket issued');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotNull);
    });

    test('every emitted type maps to a known value', () {
      for (final entry in {
        'RESERVATION': NotificationType.reservation,
        'PAYMENT': NotificationType.payment,
        'TICKET': NotificationType.ticket,
        'GENERAL': NotificationType.general,
      }.entries) {
        expect(
          AppNotification.fromJson({...json, 'notification_type': entry.key})
              .type,
          entry.value,
        );
      }
    });
  });

  group('Station', () {
    test('parses a station row', () {
      final station = Station.fromJson({
        'id': '891a9d89-7c1c-4064-8556-475ace7d6fd2',
        'name': 'Khartoum',
        'code': 'KRT',
        'is_active': true,
      });

      expect(station.name, 'Khartoum');
      expect(station.code, 'KRT');
    });
  });
}
