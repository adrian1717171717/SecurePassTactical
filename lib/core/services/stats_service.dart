// lib/core/services/stats_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio centralizado de estadísticas operativas.
/// Calcula personas únicas, movimientos totales, visitantes, vehículos
/// usando queries directas contra Firestore en tiempo real.
class StatsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Obtiene las estadísticas del día actual en tiempo real.
  static Stream<DailyStats> watchTodayStats() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('access_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => _calculateStats(snapshot.docs));
  }

  /// Calcula stats a partir de una lista de documentos de access_logs.
  static DailyStats _calculateStats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final Set<String> uniquePersonUids = {};
    final Set<String> uniqueVehiclePlates = {};
    final Set<String> uniqueVisitorNames = {};
    int totalEntries = 0;
    int totalExits = 0;
    int totalDenied = 0;
    int totalVehicularMovements = 0;
    int totalPedestrianMovements = 0;
    final Map<int, int> activityByHour = {};
    final Map<String, int> activityByUnit = {};
    final Map<int, int> activityByHourPedestrian = {};
    final Map<int, int> activityByHourVehicular = {};

    // Track who is currently inside (latest movement per uid)
    final Map<String, String> latestMovementByUid = {};

    // Sort by timestamp ascending to track latest movement
    final sorted = List.of(docs)..sort((a, b) {
      final ta = (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final tb = (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return ta.compareTo(tb);
    });

    for (final doc in sorted) {
      final d = doc.data();
      final eventType = (d['event_type'] as String? ?? '').toLowerCase();
      final result = (d['access_result'] as String? ?? '').toLowerCase();
      final uid = d['uid'] as String?;
      final vehiclePlate = d['vehicle_plate'] as String?;
      final unit = d['unit'] as String?;
      final ts = (d['timestamp'] as Timestamp?)?.toDate();
      final isEntry = eventType.contains('ingreso') || eventType.contains('entrada');
      final isExit = eventType.contains('salida') || eventType.contains('egreso');
      final isVehicular = eventType.contains('vehicular');
      final isVisitor = eventType.contains('visitante') || eventType.contains('visita');

      if (result == 'granted') {
        if (isEntry) totalEntries++;
        if (isExit) totalExits++;
      } else if (result == 'denied') {
        totalDenied++;
      }

      if (isVehicular) {
        totalVehicularMovements++;
        if (vehiclePlate != null && vehiclePlate.isNotEmpty) {
          uniqueVehiclePlates.add(vehiclePlate.toUpperCase());
        }
      } else {
        totalPedestrianMovements++;
      }

      if (isVisitor) {
        final name = d['person_name'] as String? ?? '';
        if (name.isNotEmpty) uniqueVisitorNames.add(name);
      }

      if (uid != null && uid.isNotEmpty) {
        uniquePersonUids.add(uid);
        if (result == 'granted') {
          latestMovementByUid[uid] = isEntry ? 'ADENTRO' : 'AFUERA';
        }
      }

      // Activity by hour (total + split)
      if (ts != null) {
        activityByHour[ts.hour] = (activityByHour[ts.hour] ?? 0) + 1;
        if (isVehicular) {
          activityByHourVehicular[ts.hour] =
              (activityByHourVehicular[ts.hour] ?? 0) + 1;
        } else {
          activityByHourPedestrian[ts.hour] =
              (activityByHourPedestrian[ts.hour] ?? 0) + 1;
        }
      }

      // Activity by unit
      if (unit != null && unit.isNotEmpty) {
        activityByUnit[unit] = (activityByUnit[unit] ?? 0) + 1;
      }
    }

    // Count people currently inside
    int peopleInside = 0;
    for (final state in latestMovementByUid.values) {
      if (state == 'ADENTRO') peopleInside++;
    }

    return DailyStats(
      uniquePersons: uniquePersonUids.length,
      peopleCurrentlyInside: peopleInside,
      totalEntries: totalEntries,
      totalExits: totalExits,
      totalDenied: totalDenied,
      uniqueVehicles: uniqueVehiclePlates.length,
      totalVehicularMovements: totalVehicularMovements,
      totalPedestrianMovements: totalPedestrianMovements,
      uniqueVisitors: uniqueVisitorNames.length,
      totalMovements: docs.length,
      activityByHour: activityByHour,
      activityByUnit: activityByUnit,
      activityByHourPedestrian: activityByHourPedestrian,
      activityByHourVehicular: activityByHourVehicular,
    );
  }
}

/// Estadísticas diarias calculadas.
class DailyStats {
  final int uniquePersons;
  final int peopleCurrentlyInside;
  final int totalEntries;
  final int totalExits;
  final int totalDenied;
  final int uniqueVehicles;
  final int totalVehicularMovements;
  final int totalPedestrianMovements;
  final int uniqueVisitors;
  final int totalMovements;
  final Map<int, int> activityByHour;
  final Map<String, int> activityByUnit;
  final Map<int, int> activityByHourPedestrian;
  final Map<int, int> activityByHourVehicular;

  const DailyStats({
    required this.uniquePersons,
    required this.peopleCurrentlyInside,
    required this.totalEntries,
    required this.totalExits,
    required this.totalDenied,
    required this.uniqueVehicles,
    required this.totalVehicularMovements,
    required this.totalPedestrianMovements,
    required this.uniqueVisitors,
    required this.totalMovements,
    required this.activityByHour,
    required this.activityByUnit,
    required this.activityByHourPedestrian,
    required this.activityByHourVehicular,
  });

  static const empty = DailyStats(
    uniquePersons: 0,
    peopleCurrentlyInside: 0,
    totalEntries: 0,
    totalExits: 0,
    totalDenied: 0,
    uniqueVehicles: 0,
    totalVehicularMovements: 0,
    totalPedestrianMovements: 0,
    uniqueVisitors: 0,
    totalMovements: 0,
    activityByHour: {},
    activityByUnit: {},
    activityByHourPedestrian: {},
    activityByHourVehicular: {},
  );
}

// ── Riverpod Provider ────────────────────────────────────────
final dailyStatsProvider = StreamProvider.autoDispose<DailyStats>((ref) {
  return StatsService.watchTodayStats();
});
