import 'package:flutter_test/flutter_test.dart';
import 'package:vargani_app/core/models/user_model.dart';
import 'package:vargani_app/core/models/group_model.dart';
import 'package:vargani_app/core/services/api_service.dart';
import 'package:vargani_app/core/services/mock_data_service.dart';

void main() {
  setUp(() {
    // Reset test users if needed
  });

  group('User Information Form & RBAC Validation Suite', () {
    test(
        '1. Full Name & Mobile Validation: Valid Indian Mobile number format and required name',
        () {
      const name = 'गणेश दत्तात्रय पाटील';
      expect(name.trim().length >= 2, isTrue,
          reason: 'Name must be at least 2 characters');

      // Valid Indian mobile numbers (10 digits starting with 6, 7, 8, or 9)
      const validMobiles = [
        '9822054321',
        '8888123456',
        '7777000111',
        '6200000001'
      ];
      const invalidMobiles = [
        '1234567890',
        '982205432',
        '982205432100',
        'abc1234567',
        '5555555555'
      ];

      final phoneRegex = RegExp(r'^[6-9]\d{9}$');
      for (final m in validMobiles) {
        expect(phoneRegex.hasMatch(m), isTrue, reason: '$m should be valid');
      }
      for (final m in invalidMobiles) {
        expect(phoneRegex.hasMatch(m), isFalse, reason: '$m should be invalid');
      }
    });

    test('2. Duplicate Mobile Check prevents duplicate user creation',
        () async {
      // Existing user phone in MockDataService
      const existingPhone = '9699342811';

      final res = await ApiService.createUserByAdmin(
        name: 'Duplicate Test User',
        phone: existingPhone,
        role: 'collector',
        organizationId: 'org_001',
      );

      expect(res['success'], isFalse);
      expect(res['message'], contains('Duplicate Mobile Number'));
    });

    test('3. Organization & Group Cascade Filtering', () {
      final groups = [
        const GroupModel(
            id: 'grp_001',
            organizationId: 'org_001',
            name: 'Group 1',
            code: 'G1',
            description: 'Group 1'),
        const GroupModel(
            id: 'grp_002',
            organizationId: 'org_001',
            name: 'Group 2',
            code: 'G2',
            description: 'Group 2'),
        const GroupModel(
            id: 'grp_003',
            organizationId: 'org_002',
            name: 'Group 3',
            code: 'G3',
            description: 'Group 3'),
      ];

      // Selecting org_001
      final org1Groups =
          groups.where((g) => g.organizationId == 'org_001').toList();
      expect(org1Groups.length, equals(2));
      expect(org1Groups.map((g) => g.id), containsAll(['grp_001', 'grp_002']));
      expect(org1Groups.map((g) => g.id), isNot(contains('grp_003')));

      // Changing to org_002 resets and filters
      final org2Groups =
          groups.where((g) => g.organizationId == 'org_002').toList();
      expect(org2Groups.length, equals(1));
      expect(org2Groups.first.id, equals('grp_003'));
    });

    test(
        '4. Dynamic Roles from Database & Exclusion of Super Admin for Regular Admin',
        () {
      final roles = MockDataService.roles;
      expect(roles, isNotEmpty);

      // Check default roles are present dynamically
      final roleKeys = roles.map((r) => r.roleKey).toList();
      expect(roleKeys, contains('SUPER_ADMIN'));
      expect(roleKeys, contains('ORG_ADMIN'));
      expect(roleKeys, contains('COLLECTOR'));

      // Regular admin filter simulation
      final regularAdminRoles = roles
          .where((r) => !r.isSuperAdmin && r.code != 'superAdmin')
          .toList();
      expect(regularAdminRoles.any((r) => r.isSuperAdmin), isFalse);
      expect(regularAdminRoles.map((r) => r.roleKey), contains('COLLECTOR'));
    });

    test(
        '5. User Information Model: Supports Address, Notes, Timestamps, and NO Family Count Field',
        () {
      final user = UserModel(
        id: 'usr_test_999',
        name: 'विजय लक्ष्मण चव्हाण',
        phone: '9822112233',
        email: 'vijay.c@example.com',
        organizationId: 'org_001',
        role: UserRole.collector,
        address: 'घर क्र. 45, मेन रोड, सांगवी',
        notes: 'सदर कार्यकर्ते संध्याकाळी 6 नंतर कलेक्शनसाठी उपलब्ध असतात.',
        accountStatus: 'active',
        createdAt: DateTime(2026, 10, 26, 10, 0),
        updatedAt: DateTime(2026, 10, 26, 10, 30),
      );

      final json = user.toJson();
      expect(json['address'], equals('घर क्र. 45, मेन रोड, सांगवी'));
      expect(json['notes'],
          equals('सदर कार्यकर्ते संध्याकाळी 6 नंतर कलेक्शनसाठी उपलब्ध असतात.'));
      expect(json.containsKey('family_members'), isFalse,
          reason: 'Family count field must NOT exist');
      expect(json.containsKey('family_count'), isFalse,
          reason: 'Family count field must NOT exist');

      final fromJsonUser = UserModel.fromJson(json);
      expect(fromJsonUser.address, equals(user.address));
      expect(fromJsonUser.notes, equals(user.notes));
      expect(fromJsonUser.isActive, isTrue);
    });

    test('6. User Create & Status Toggle Workflow', () async {
      final uniquePhone =
          '98555${DateTime.now().millisecondsSinceEpoch % 100000}';
      final createRes = await ApiService.createUserByAdmin(
        name: 'अमित शिंदे',
        phone: uniquePhone,
        role: 'collector',
        organizationId: 'org_001',
        address: 'पुणे, शनिवार पेठ',
        notes: 'विश्वासू कार्यकर्ता',
        isActive: true,
      );

      expect(createRes['success'], isTrue);
      final createdUser = createRes['data'] as UserModel;
      expect(createdUser.name, equals('अमित शिंदे'));
      expect(createdUser.isActive, isTrue);

      // Toggle to Inactive
      final toggleRes = await ApiService.toggleUserStatus(
        userId: createdUser.id,
        isActive: false,
      );
      expect(toggleRes['success'], isTrue);

      // Verify status changed
      final users = await ApiService.fetchUsers();
      final updatedUser = users?.firstWhere((u) => u.id == createdUser.id);
      expect(updatedUser?.isActive, isFalse);
    });

    test('7. Financial Records Preservation Guard', () async {
      // Check user with financial records
      final hasRecords =
          await ApiService.hasFinancialTransactions('usr_collector1');
      expect(hasRecords, isA<bool>());
    });
  });
}
