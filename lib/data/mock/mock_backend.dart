import 'dart:math';

import '../../core/enums/app_enums.dart';
import '../../models/app_notification.dart';
import '../../models/payment.dart';
import '../../models/reservation.dart';
import '../../models/schedule.dart';
import '../../models/station.dart';
import '../../models/ticket.dart';
import '../../models/train.dart';
import '../../models/user.dart';
import '../api_exception.dart';

/// In-memory fake backend so the whole reserve → pay → review → ticket →
/// notify chain is demonstrable without a server. Every mock service talks to
/// this single instance, so state stays consistent across screens.
///
/// This entire file is throwaway once the real endpoints are wired: the
/// service interfaces (AuthService, CatalogService, …) are what the UI
/// depends on, and a real HTTP implementation simply replaces the mock one.
class MockBackend {
  MockBackend._();
  static final MockBackend instance = MockBackend._();

  final _rng = Random();

  final List<Station> stations = [
    const Station(id: 'st1', name: 'Khartoum', city: 'Khartoum', code: 'KRT'),
    const Station(id: 'st2', name: 'Atbara', city: 'River Nile', code: 'ATB'),
    const Station(id: 'st3', name: 'Wadi Halfa', city: 'Northern', code: 'WHF'),
    const Station(id: 'st4', name: 'Port Sudan', city: 'Red Sea', code: 'PZU'),
    const Station(id: 'st5', name: 'Kosti', city: 'White Nile', code: 'KST'),
    const Station(id: 'st6', name: 'Nyala', city: 'South Darfur', code: 'NYL'),
  ];

  final List<Train> trains = [
    const Train(
        id: 'tr1', trainNumber: 'T-100', name: 'Nile Express', capacity: 320),
    const Train(
        id: 'tr2', trainNumber: 'T-200', name: 'Red Sea Line', capacity: 400),
    const Train(
        id: 'tr3', trainNumber: 'T-300', name: 'Northern Star', capacity: 280),
    const Train(
        id: 'tr4', trainNumber: 'T-400', name: 'White Nile Rail', capacity: 250),
    const Train(
        id: 'tr5', trainNumber: 'T-500', name: 'Darfur Link', capacity: 300),
  ];

  late List<Schedule> schedules = _seedSchedules();
  final List<Reservation> reservations = [];
  final List<Payment> payments = [];
  final List<Ticket> tickets = [];
  final List<AppNotification> notifications = [];

  User? currentUser;

  // ---- seeding -------------------------------------------------------------

  List<Schedule> _seedSchedules() {
    final now = DateTime.now();
    final routes = [
      ['Khartoum', 'Atbara', 'Nile Express', 6, 320.0],
      ['Khartoum', 'Port Sudan', 'Red Sea Line', 14, 750.0],
      ['Atbara', 'Wadi Halfa', 'Northern Star', 9, 480.0],
      ['Khartoum', 'Kosti', 'White Nile Rail', 4, 260.0],
      ['Kosti', 'Nyala', 'Darfur Link', 16, 690.0],
      ['Port Sudan', 'Khartoum', 'Red Sea Line', 14, 750.0],
    ];
    return List.generate(routes.length, (i) {
      final r = routes[i];
      final dep = now.add(Duration(hours: 8 + i * 9));
      return Schedule(
        id: 'sch${i + 1}',
        trainName: r[2] as String,
        departureStation: r[0] as String,
        arrivalStation: r[1] as String,
        departureTime: dep,
        arrivalTime: dep.add(Duration(hours: r[3] as int)),
        ticketPrice: r[4] as double,
        seatsAvailable: 12 + _rng.nextInt(60),
        status: ScheduleStatus.available,
      );
    });
  }

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';

  Train createTrain({
    required String trainNumber,
    required String name,
    required int capacity,
    required String trainType,
  }) {
    if (trains.any((t) => t.trainNumber == trainNumber)) {
      throw const ApiException(
        'A train with this number already exists.',
        statusCode: 400,
        fieldErrors: {'train_number': 'This train number is already taken.'},
      );
    }
    final train = Train(
      id: _id('tr'),
      trainNumber: trainNumber,
      name: name,
      capacity: capacity,
      trainType: trainType,
    );
    trains.add(train);
    return train;
  }

  Station createStation({required String name, required String code}) {
    if (stations.any((s) => s.code == code)) {
      throw const ApiException(
        'A station with this code already exists.',
        statusCode: 400,
        fieldErrors: {'code': 'This code is already taken.'},
      );
    }
    final station = Station(id: _id('st'), name: name, code: code);
    stations.add(station);
    return station;
  }

  Schedule createSchedule({
    required String trainId,
    required String departureStationId,
    required String arrivalStationId,
    required DateTime departure,
    required DateTime arrival,
    required double ticketPrice,
    required int availableSeats,
  }) {
    String stationName(String id) =>
        stations.firstWhere((s) => s.id == id).name;

    final schedule = Schedule(
      id: _id('sch'),
      trainName: trains.firstWhere((t) => t.id == trainId).name,
      departureStation: stationName(departureStationId),
      arrivalStation: stationName(arrivalStationId),
      departureTime: departure,
      arrivalTime: arrival,
      ticketPrice: ticketPrice,
      seatsAvailable: availableSeats,
      status: ScheduleStatus.available,
    );
    schedules = [...schedules, schedule];
    return schedule;
  }

  Schedule scheduleById(String id) =>
      schedules.firstWhere((s) => s.id == id,
          orElse: () => throw const ApiException('Schedule not found.',
              statusCode: 404));

  // ---- reservations --------------------------------------------------------

  Reservation createReservation(String scheduleId, int seats) {
    final schedule = scheduleById(scheduleId);
    if (!schedule.status.isBookable) {
      throw const ApiException('This schedule is no longer available.');
    }
    if (schedule.departureTime != null &&
        schedule.departureTime!.isBefore(DateTime.now())) {
      throw const ApiException('This train has already departed.');
    }
    if (seats <= 0) {
      throw const ApiException('Please select at least one seat.');
    }
    if (seats > schedule.seatsAvailable) {
      throw ApiException(
        'Only ${schedule.seatsAvailable} seat(s) left on this train.',
      );
    }

    // Reduce availability optimistically.
    final idx = schedules.indexWhere((s) => s.id == scheduleId);
    schedules[idx] = Schedule(
      id: schedule.id,
      trainName: schedule.trainName,
      departureStation: schedule.departureStation,
      arrivalStation: schedule.arrivalStation,
      departureTime: schedule.departureTime,
      arrivalTime: schedule.arrivalTime,
      ticketPrice: schedule.ticketPrice,
      seatsAvailable: schedule.seatsAvailable - seats,
      status: schedule.status,
    );

    final reservation = Reservation(
      id: _id('res'),
      scheduleId: schedule.id,
      seats: seats,
      totalPrice: schedule.ticketPrice * seats,
      status: ReservationStatus.pendingPayment,
      createdAt: DateTime.now(),
      trainName: schedule.trainName,
      departureStation: schedule.departureStation,
      arrivalStation: schedule.arrivalStation,
      departureTime: schedule.departureTime,
      arrivalTime: schedule.arrivalTime,
    );
    reservations.insert(0, reservation);
    _notify(NotificationType.reservation, 'Reservation created',
        'Your reservation for ${schedule.trainName} is awaiting payment.');
    return reservation;
  }

  Reservation _updateReservationStatus(String id, ReservationStatus status) {
    final idx = reservations.indexWhere((r) => r.id == id);
    final r = reservations[idx];
    final updated = Reservation(
      id: r.id,
      scheduleId: r.scheduleId,
      seats: r.seats,
      totalPrice: r.totalPrice,
      status: status,
      createdAt: r.createdAt,
      trainName: r.trainName,
      departureStation: r.departureStation,
      arrivalStation: r.arrivalStation,
      departureTime: r.departureTime,
      arrivalTime: r.arrivalTime,
    );
    reservations[idx] = updated;
    return updated;
  }

  // ---- payments ------------------------------------------------------------

  Payment createPayment(String reservationId, String receiptPath) {
    final reservation = reservations.firstWhere(
      (r) => r.id == reservationId,
      orElse: () =>
          throw const ApiException('Reservation not found.', statusCode: 404),
    );

    final existing = payments.where((p) =>
        p.reservationId == reservationId && p.status != PaymentStatus.rejected);
    if (existing.isNotEmpty) {
      throw const ApiException(
        'A payment for this reservation is already under review.',
      );
    }

    final payment = Payment(
      id: _id('pay'),
      reservationId: reservationId,
      receiptUrl: receiptPath,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      trainName: reservation.trainName,
      departureStation: reservation.departureStation,
      arrivalStation: reservation.arrivalStation,
      departureTime: reservation.departureTime,
      totalPrice: reservation.totalPrice,
      seats: reservation.seats,
      passengerName: currentUser?.fullName ?? 'Passenger',
    );
    payments.insert(0, payment);
    _updateReservationStatus(reservationId, ReservationStatus.paymentSubmitted);
    _notify(NotificationType.payment, 'Payment submitted',
        'Your receipt is under review. We\'ll notify you once it\'s checked.');
    return payment;
  }

  Payment reviewPayment(String paymentId, PaymentStatus decision, String note) {
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) {
      throw const ApiException('Payment not found.', statusCode: 404);
    }
    final p = payments[idx];
    final updated = Payment(
      id: p.id,
      reservationId: p.reservationId,
      receiptUrl: p.receiptUrl,
      status: decision,
      adminNote: note,
      createdAt: p.createdAt,
      trainName: p.trainName,
      departureStation: p.departureStation,
      arrivalStation: p.arrivalStation,
      departureTime: p.departureTime,
      totalPrice: p.totalPrice,
      seats: p.seats,
      passengerName: p.passengerName,
    );
    payments[idx] = updated;

    if (decision == PaymentStatus.approved) {
      _updateReservationStatus(p.reservationId, ReservationStatus.confirmed);
      _issueTicket(p);
      _notify(NotificationType.ticket, 'Ticket issued',
          'Your payment was approved. Your ticket is ready to view.');
    } else if (decision == PaymentStatus.rejected) {
      // Reservation returns to pending payment so the passenger can resubmit.
      _updateReservationStatus(
          p.reservationId, ReservationStatus.pendingPayment);
      _notify(NotificationType.payment, 'Payment rejected',
          note.isEmpty ? 'Please resubmit a valid receipt.' : note);
    }
    return updated;
  }

  void _issueTicket(Payment p) {
    final reservation = reservations.firstWhere(
      (r) => r.id == p.reservationId,
      orElse: () => throw const ApiException('Reservation not found.'),
    );
    tickets.insert(
      0,
      Ticket(
        id: _id('tkt'),
        ticketNumber:
            'SR-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}',
        passengerName: p.passengerName ?? 'Passenger',
        trainName: reservation.trainName,
        departureStation: reservation.departureStation,
        arrivalStation: reservation.arrivalStation,
        departureTime: reservation.departureTime,
        arrivalTime: reservation.arrivalTime,
        seats: reservation.seats,
        totalPrice: reservation.totalPrice,
        status: 'VALID',
      ),
    );
  }

  // ---- notifications -------------------------------------------------------

  void _notify(NotificationType type, String title, String message) {
    notifications.insert(
      0,
      AppNotification(
        id: _id('ntf'),
        type: type,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  void markRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) notifications[idx] = notifications[idx].copyWith(isRead: true);
  }

  void markAllRead() {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
  }

  /// Seed a couple of staff-queue payments so a STAFF login sees a non-empty
  /// review list immediately.
  void seedStaffQueueIfEmpty() {
    if (payments.any((p) => p.status == PaymentStatus.pending)) return;
    final now = DateTime.now();
    payments.addAll([
      Payment(
        id: _id('pay'),
        reservationId: _id('res'),
        receiptUrl: 'https://picsum.photos/seed/receipt1/600/800',
        status: PaymentStatus.pending,
        createdAt: now.subtract(const Duration(hours: 3)),
        trainName: 'Red Sea Line',
        departureStation: 'Khartoum',
        arrivalStation: 'Port Sudan',
        departureTime: now.add(const Duration(days: 1)),
        totalPrice: 1500,
        seats: 2,
        passengerName: 'Amina Yusuf',
      ),
      Payment(
        id: _id('pay'),
        reservationId: _id('res'),
        receiptUrl: 'https://picsum.photos/seed/receipt2/600/800',
        status: PaymentStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
        trainName: 'Nile Express',
        departureStation: 'Khartoum',
        arrivalStation: 'Atbara',
        departureTime: now.add(const Duration(hours: 20)),
        totalPrice: 320,
        seats: 1,
        passengerName: 'Omar Bashir',
      ),
    ]);
  }
}
