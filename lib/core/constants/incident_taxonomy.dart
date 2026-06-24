final class IncidentStateIds {
  IncidentStateIds._();

  static const int created = 1;
  static const int accepted = 2;
  static const int inRoute = 3;
  static const int arrived = 4;
  static const int resolved = 5;
  static const int closed = 6;
}

final class IncidentStateNames {
  IncidentStateNames._();

  static const String created = 'created';
  static const String accepted = 'accepted';
  static const String inRoute = 'in_route';
  static const String arrived = 'arrived';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
}

final class IncidentTypeIds {
  IncidentTypeIds._();

  static const int sos = 1;
}

final class IncidentTypeNames {
  IncidentTypeNames._();

  static const String sos = 'sos';
}

final class IncidentStateRules {
  IncidentStateRules._();

  static const Set<int> attendBlockedStateIds = {
    IncidentStateIds.inRoute,
    IncidentStateIds.resolved,
    IncidentStateIds.closed,
  };

  static const Set<String> attendBlockedStateNames = {
    IncidentStateNames.inRoute,
    IncidentStateNames.resolved,
    IncidentStateNames.closed,
  };

  static const Set<int> pendingStateIds = {
    IncidentStateIds.created,
    IncidentStateIds.accepted,
  };

  static bool blocksAttendById(int? stateId) =>
      stateId != null && attendBlockedStateIds.contains(stateId);

  static bool blocksAttendByName(String? stateName) {
    if (stateName == null) return false;
    return attendBlockedStateNames.contains(stateName.trim().toLowerCase());
  }

  static bool isPendingById(int? stateId) =>
      stateId != null && pendingStateIds.contains(stateId);
}
