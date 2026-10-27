class JoinRequestModel {
  final String id;
  final String groupId;
  final String? groupName;
  final String? groupCode;
  final String? organizationId;
  final String? organizationName;
  final String userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String requestStatus; // 'pending', 'approved', 'rejected', 'cancelled'
  final String message;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const JoinRequestModel({
    required this.id,
    required this.groupId,
    this.groupName,
    this.groupCode,
    this.organizationId,
    this.organizationName,
    required this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.requestStatus = 'pending',
    this.message = '',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get isPending => requestStatus.toLowerCase() == 'pending';
  bool get isApproved => requestStatus.toLowerCase() == 'approved';
  bool get isRejected => requestStatus.toLowerCase() == 'rejected';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'request_status': requestStatus,
      'message': message,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    String? gName;
    String? gCode;
    String? orgId;
    String? orgName;
    if (json['groups'] is Map) {
      final g = json['groups'] as Map;
      gName = g['name'] as String?;
      gCode = g['code'] as String?;
      orgId = g['organization_id'] as String?;
      if (g['organizations'] is Map) {
        orgName = (g['organizations'] as Map)['name'] as String?;
      }
    }

    String? uName;
    String? uPhone;
    String? uEmail;
    if (json['profiles'] is Map) {
      final p = json['profiles'] as Map;
      uName = p['full_name'] as String?;
      uPhone = p['phone'] as String?;
      uEmail = p['email'] as String?;
    }

    return JoinRequestModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      groupName: gName ?? json['group_name'] as String?,
      groupCode: gCode ?? json['group_code'] as String?,
      organizationId: orgId ?? json['organization_id'] as String?,
      organizationName: orgName ?? json['organization_name'] as String?,
      userId: json['user_id'] as String? ?? '',
      userName: uName ?? json['user_name'] as String?,
      userPhone: uPhone ?? json['user_phone'] as String?,
      userEmail: uEmail ?? json['user_email'] as String?,
      requestStatus: json['request_status'] as String? ?? 'pending',
      message: json['message'] as String? ?? '',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  JoinRequestModel copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? groupCode,
    String? organizationId,
    String? organizationName,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? requestStatus,
    String? message,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupCode: groupCode ?? this.groupCode,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      requestStatus: requestStatus ?? this.requestStatus,
      message: message ?? this.message,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
