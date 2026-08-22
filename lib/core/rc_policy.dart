abstract final class RcPolicy {
  static const parishes = <String>[
    'Hanover','Westmoreland','St. James','Trelawny','St. Elizabeth','St. Ann',
    'Clarendon','Manchester','St. Catherine','Kingston','St. Andrew','St. Mary',
    'Portland','St. Thomas',
  ];

  static const roles = <String>[
    'Site Supervisor','Regional Supervisor','Construction Specialist',
    'Construction Engineer','Community Admin','Technical Admin','Admin',
  ];

  static const privilegeLabels = <String, String>{
    'viewAllParishes': 'View all parishes',
    'editControl': 'Edit Control of Works',
    'submitScope': 'Submit Scope of Work',
    'approveScope': 'Approve Scope of Work',
    'viewAdmin': 'Open Admin Dashboard',
    'manageFolders': 'Manage templates/folders',
    'manageUsers': 'Manage users',
    'exportData': 'Export PDF / Excel',
    'raiseIssues': 'Raise issues',
    'reviewControl': 'Review Control of Works',
    'reviewPayments': 'Review payments',
    'approvePayments': 'Approve payments',
    'approveNotice': 'Approve Notice of Completion',
    'managePrivileges': 'Manage privileges',
    'viewAuditLog': 'View audit log',
    'messageAllUsers': 'Message all users',
  };
}
