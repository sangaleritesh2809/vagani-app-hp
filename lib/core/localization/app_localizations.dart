class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Vargani Pro',
      'appSubtitle': 'Household Contribution & Financial Transparency',
      'dashboard': 'Dashboard',
      'households': 'Households',
      'campaigns': 'Campaigns',
      'collections': 'Collections',
      'receipts': 'Receipts',
      'handovers': 'Cash Handovers',
      'expenses': 'Expenses',
      'complaints': 'Complaints',
      'reports': 'Reports & Analytics',
      'transparency': 'Public Transparency',
      'settings': 'Settings',
      
      // Roles
      'superAdmin': 'Super Admin',
      'orgAdmin': 'Organization Admin',
      'treasurer': 'Treasurer',
      'collector': 'Collection Agent',
      'citizen': 'Citizen / Public',
      'roleSwitch': 'Switch Role',
      'currentRole': 'Current Role',
      
      // Stats
      'expectedTotal': 'Expected Total',
      'verifiedReceived': 'Verified Received',
      'remainingAmount': 'Remaining Due',
      'approvedExpenses': 'Approved Expenses',
      'paidExpenses': 'Paid Expenses',
      'availableBalance': 'Available Balance',
      'cashInHand': 'Cash in Hand',
      'completionRate': 'Collection Progress',
      
      // Household
      'headOfFamily': 'Head of Family Name',
      'memberCount': 'Family Members',
      'mobileNumber': 'Mobile Number',
      'villageArea': 'Village / Area / Ward',
      'perPersonRate': 'Rate per Person',
      'registerHousehold': 'Register Household',
      'pending': 'Pending',
      'partiallyPaid': 'Partially Paid',
      'paid': 'Paid',
      
      // Payment & Receipt
      'recordPayment': 'Record Contribution',
      'paymentMode': 'Payment Mode',
      'cash': 'Cash',
      'upi': 'UPI (QR / App)',
      'bankTransfer': 'Bank Transfer / NEFT',
      'other': 'Other Mode',
      'collectedBy': 'Collected By (Read-only)',
      'receivedBy': 'Authorized Received By',
      'referenceId': 'UTR / Ref ID',
      'receiptNo': 'Receipt Number',
      'downloadPdf': 'Download PDF',
      'shareWhatsApp': 'Share on WhatsApp',
      'cancelReceipt': 'Cancel Receipt',
      
      // Handover
      'initiateHandover': 'Submit Cash Handover',
      'handoverFrom': 'Handover From',
      'handoverTo': 'Handover To',
      'confirmReceipt': 'Confirm Receipt',
      'confirmed': 'Confirmed',
      'rejected': 'Rejected',
      'handoverStatus': 'Handover Status',
      
      // Expenses
      'addExpense': 'Add Expense',
      'expenseCategory': 'Category',
      'billNumber': 'Bill / Invoice No',
      'vendorPayee': 'Vendor / Payee',
      'proofUploaded': 'Proof Uploaded',
      'proofNotUploaded': 'Proof Not Uploaded',
      'approve': 'Approve',
      'reject': 'Reject',
      'publicVisible': 'Publicly Visible',
      
      // Complaints
      'submitComplaint': 'File Complaint / Inquiry',
      'complaintType': 'Complaint Type',
      'complaintStatus': 'Status',
      'escalateSuperAdmin': 'Escalate to Super Admin',
      'resolve': 'Resolve',
      'resolutionNotes': 'Resolution Notes',
      
      // Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'search': 'Search by name, area or ID...',
      'filter': 'Filter',
      'exportCsv': 'Export Excel / CSV',
      'language': 'Language / भाषा',
    },
    'mr': {
      'appName': 'वर्गणी प्रो (Vargani)',
      'appSubtitle': 'पारदर्शक वर्गणी संकलन आणि हिशोब व्यवस्थापन',
      'dashboard': 'डॅशबोर्ड',
      'households': 'कुटुंबे / घरे',
      'campaigns': 'उत्सव / मोहीम',
      'collections': 'वर्गणी संकलन',
      'receipts': 'पावत्या',
      'handovers': 'रक्कम सुपूर्द (हँडओव्हर)',
      'expenses': 'खर्च व्यवस्थापन',
      'complaints': 'तक्रार निवारण',
      'reports': 'अहवाल व आकडेवारी',
      'transparency': 'सार्वजनिक पारदर्शकता',
      'settings': 'सेटिंग्ज',
      
      // Roles
      'superAdmin': 'सुपर ॲडमिन',
      'orgAdmin': 'संस्थापक / मंडळ प्रमुख',
      'treasurer': 'खजिनदार / हिशोबनीस',
      'collector': 'वर्गणी संकलन प्रतिनिधी',
      'citizen': 'नागरिक / देणगीदार',
      'roleSwitch': 'भूमिका बदला',
      'currentRole': 'सध्याची भूमिका',
      
      // Stats
      'expectedTotal': 'अपेक्षित वर्गणी',
      'verifiedReceived': 'एकूण जमा रक्कम',
      'remainingAmount': 'शिल्लक येणे बाकी',
      'approvedExpenses': 'मंजूर खर्च',
      'paidExpenses': 'झालेला एकूण खर्च',
      'availableBalance': 'शिल्लक रोकड निधी',
      'cashInHand': 'स्वतःकडील रोकड',
      'completionRate': 'संकलन प्रगती',
      
      // Household
      'headOfFamily': 'कुटुंबप्रमुखाचे नाव',
      'memberCount': 'कुटुंबातील एकूण सदस्य',
      'mobileNumber': 'मोबाईल नंबर',
      'villageArea': 'गाव / गल्ली / वॉर्ड',
      'perPersonRate': 'प्रति व्यक्ती दर',
      'registerHousehold': 'नवीन कुटुंब नोंदणी',
      'pending': 'प्रलंबित (बाकी)',
      'partiallyPaid': 'अंशतः जमा',
      'paid': 'पूर्ण जमा',
      
      // Payment & Receipt
      'recordPayment': 'वर्गणी जमा करा',
      'paymentMode': 'पेमेंट पद्धत',
      'cash': 'रोख (Cash)',
      'upi': 'युपीआय (UPI / QR)',
      'bankTransfer': 'बँक ट्रान्सफर',
      'other': 'इतर',
      'collectedBy': 'संकलनकर्ता (ऑटो)',
      'receivedBy': 'अधिकृत प्राप्तकर्ता',
      'referenceId': 'युटीआर / संदर्भ क्रमांक',
      'receiptNo': 'पावती क्रमांक',
      'downloadPdf': 'पीडीएफ डाउनलोड',
      'shareWhatsApp': 'व्हॉट्सॲपवर पाठवा',
      'cancelReceipt': 'पावती रद्द करा',
      
      // Handover
      'initiateHandover': 'रोकड जमा करा (हँडओव्हर)',
      'handoverFrom': 'कोणाकडून',
      'handoverTo': 'कोणाकडे',
      'confirmReceipt': 'रक्कम मिळाल्याची पुष्टी',
      'confirmed': 'स्वीकृत',
      'rejected': 'नाकारले',
      'handoverStatus': 'हस्तांतरण स्थिती',
      
      // Expenses
      'addExpense': 'नवीन खर्च नोंदवा',
      'expenseCategory': 'खर्चाचा प्रकार',
      'billNumber': 'बिल क्रमांक',
      'vendorPayee': 'दुकान / व्यक्तीचे नाव',
      'proofUploaded': 'बिल जोडले आहे',
      'proofNotUploaded': 'बिल जोडलेले नाही',
      'approve': 'मंजूर करा',
      'reject': 'नाकारा',
      'publicVisible': 'सार्वजनिक दिसेल',
      
      // Complaints
      'submitComplaint': 'तक्रार / विचारणा नोंदवा',
      'complaintType': 'तक्रारीचा प्रकार',
      'complaintStatus': 'स्थिती',
      'escalateSuperAdmin': 'सुपर ॲडमिनकडे पाठवा',
      'resolve': 'निवारण झाले',
      'resolutionNotes': 'निवारण तपशील',
      
      // Actions
      'save': 'जतन करा',
      'cancel': 'रद्द करा',
      'submit': 'सादर करा',
      'search': 'नाव, पत्ता किंवा आयडीने शोधा...',
      'filter': 'फिल्टर',
      'exportCsv': 'एक्सेल / सीएसव्ही निर्यात',
      'language': 'भाषा / Language',
    }
  };

  String tr(String key) {
    return _localizedValues[languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
