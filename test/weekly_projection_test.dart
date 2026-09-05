import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/weekly_projection.dart';

WeeklyAdminProjectionFile testFile({
  required String owner,
  required String parish,
}) {
  final week = rcWeekStarting(DateTime(2026, 9, 9));
  return WeeklyAdminProjectionFile(
    id: 'FILE-$owner',
    weekStarting: week,
    ownerId: owner,
    ownerName: owner,
    position: 'Technical Admin',
    parish: parish,
    cluster: 'Cluster 1',
    days: defaultAdminWorkWeek(week),
    signatureStrokes: const <List<SignaturePointData>>[],
    status: WeeklyProjectionStatus.draft,
    updatedAt: DateTime(2026, 9, 5),
  );
}

void main() {
  test('Monday-Friday defaults to 09:00-17:00', () {
    final days = defaultAdminWorkWeek(DateTime(2026, 9, 9));

    expect(days.length, 7);
    expect(days.where((day) => day.enabled).length, 5);
    expect(days.first.startMinutes, 9 * 60);
    expect(days.first.endMinutes, 17 * 60);
    expect(
      days.where((day) => day.enabled).fold<double>(
            0,
            (sum, day) => sum + day.plannedHours,
          ),
      40,
    );
  });

  test('construction specialist, admin and regional supervisor see all', () {
    final otherParish = testFile(owner: 'u2', parish: 'Westmoreland');

    for (final role in <String>[
      'Construction Specialist',
      'Admin',
      'Regional Site Supervisor',
    ]) {
      expect(
        WeeklyProjectionAccess.canView(
          viewerRole: role,
          viewerId: 'u1',
          viewerParishes: const <String>['Hanover'],
          file: otherParish,
        ),
        isTrue,
      );
    }
  });

  test('site supervisor sees all staff for assigned parish only', () {
    final hanover = testFile(owner: 'u2', parish: 'Hanover');
    final westmoreland = testFile(owner: 'u3', parish: 'Westmoreland');

    expect(
      WeeklyProjectionAccess.canView(
        viewerRole: 'Site Supervisor',
        viewerId: 'u1',
        viewerParishes: const <String>['Hanover'],
        file: hanover,
      ),
      isTrue,
    );
    expect(
      WeeklyProjectionAccess.canView(
        viewerRole: 'Site Supervisor',
        viewerId: 'u1',
        viewerParishes: const <String>['Hanover'],
        file: westmoreland,
      ),
      isFalse,
    );
  });

  test('technical and community admin see only their own file', () {
    final mine = testFile(owner: 'u1', parish: 'Hanover');
    final other = testFile(owner: 'u2', parish: 'Hanover');

    for (final role in <String>['Technical Admin', 'Community Admin']) {
      expect(
        WeeklyProjectionAccess.canView(
          viewerRole: role,
          viewerId: 'u1',
          viewerParishes: const <String>['Hanover'],
          file: mine,
        ),
        isTrue,
      );
      expect(
        WeeklyProjectionAccess.canView(
          viewerRole: role,
          viewerId: 'u1',
          viewerParishes: const <String>['Hanover'],
          file: other,
        ),
        isFalse,
      );
    }
  });

  test('only owner can edit a draft and submitted file is locked', () {
    final file = testFile(owner: 'u2', parish: 'Hanover');

    expect(
      WeeklyProjectionAccess.canEdit(viewerId: 'u1', file: file),
      isFalse,
    );
    expect(
      WeeklyProjectionAccess.canEdit(viewerId: 'u2', file: file),
      isTrue,
    );

    file.status = WeeklyProjectionStatus.submitted;

    expect(
      WeeklyProjectionAccess.canEdit(viewerId: 'u2', file: file),
      isFalse,
    );
  });

  test('weekly file json preserves daily details and signature', () {
    final file = testFile(owner: 'u1', parish: 'Hanover');
    file.days.first.detail = 'Technical visits and tracker update';
    file.signatureStrokes = const <List<SignaturePointData>>[
      <SignaturePointData>[
        SignaturePointData(x: .1, y: .4),
        SignaturePointData(x: .7, y: .5),
      ],
    ];

    final restored = WeeklyAdminProjectionFile.fromJson(file.toJson());

    expect(restored.ownerId, 'u1');
    expect(restored.days.first.detail, contains('Technical visits'));
    expect(restored.signatureStrokes.single.length, 2);
  });
}
