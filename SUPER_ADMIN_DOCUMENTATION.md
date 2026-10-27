# वर्गणी प्रो (Vargani Pro) - सुपर ॲडमिन दस्तऐवजीकरण (Super Admin Documentation)

> **दस्तऐवज:** सर्वोच्च प्रशासक कार्यप्रणाली आणि तांत्रिक मार्गदर्शिका  
> **अधिकार पातळी (Privilege Level):** System-Wide Root / Super Admin (`*` Permissions)  
> **अंतिम सुधारणा तारीख:** 26 ऑक्टोबर 2026

---

## १. सुपर ॲडमिन म्हणजे काय? (What is Super Admin?)

**सुपर ॲडमिन (सर्वोच्च प्रशासक)** हा 'वर्गणी प्रो' (Vargani Pro) प्लॅटफॉर्मचा मुख्य तांत्रिक व प्रशासकीय नियंत्रक असतो. 
सामान्य 'संस्था ॲडमिन' (Org Admin) फक्त स्वतःच्या एका मंडळाचे काम पाहू शकतो; मात्र **सुपर ॲडमिन** हा संपूर्ण ॲपमधील **सर्व मंडळे (Multi-Tenant Organizations), त्यांचे सर्व प्रभाग, सर्व वापरकर्ते आणि संपूर्ण आर्थिक व्यवहारांवर सर्वोच्च नियंत्रण** ठेवतो.

### सुपर ॲडमिनचे विशेष अधिकार:
* सर्व संस्था/मंडळे (Organizations) तयार करणे, संपादित करणे किंवा बंद करणे.
* संपूर्ण सिस्टीमचे RBAC (Role-Based Access Control) आणि परवानग्या नियंत्रित करणे.
* कोणत्याही संस्थेच्या डेटाचे केंद्रीय वित्तीय निरीक्षण (Central Financial Auditing).
* सर्व डिजिटल नोंदींचे सुरक्षा परीक्षण (Global Audit Logging).

---

## २. सुपर ॲडमिन कन्सोल - १५ मुख्य मॉड्यूल्स (Console Modules)

सुपर ॲडमिन पॅनेलमध्ये खालील १५ प्रगत मॉड्यूल्स उपलब्ध आहेत:

```
[ सुपर ॲडमिन कन्सोल ]
  ├── 1. डॅशबोर्ड (Global Dashboard & Metrics)
  ├── 2. संस्था व्यवस्थापन (Multi-Org Management)
  ├── 3. गट / प्रभाग व्यवस्थापन (Groups & Wards)
  ├── 4. युजर्स व्यवस्थापन (Global User Directory)
  ├── 5. भूमिका व्यवस्थापन (Dynamic Roles & System Roles)
  ├── 6. परवानग्या (Granular Permission Control)
  ├── 7. भूमिका वाटप (Role Assignment & Transfer)
  ├── 8. पदानुक्रम रचना (Org -> Group -> Member Hierarchy)
  ├── 9. जोडणी विनंत्या (Global Join Requests)
  ├── 10. वर्गणी संकलन मॉनिटरिंग (Central Collections)
  ├── 11. खर्च मॉनिटरिंग (Central Expenses)
  ├── 12. केंद्रीय अहवाल (Global Reports & Analytics)
  ├── 13. सिक्युरिटी ऑडिट लॉग्स (Security & Audit Trail)
  ├── 14. खात्याची स्थिती (Account Status & Tenant Activation)
  └── 15. सिस्टीम सेटिंग्ज (System & Security Config)
```

---

### १. मुख्य डॅशबोर्ड (Global Dashboard Overview)
* **थेट KPI कार्ड्स (Real-time Indicators):**
  - एकूण नोंदणीकृत संस्था (Organizations Count)
  - एकूण गट / प्रभाग (Total Groups)
  - एकूण नोंदणीकृत वापरकर्ते (Total Users)
  - प्रलंबित विनंत्या (Pending Join Requests)
  - सर्व संस्थांची एकत्रित जमा वर्गणी (Global Total Collections)
  - सर्व संस्थांचा एकत्रित खर्च (Global Total Expenses)
  - सिस्टीम रोल्स व परवानग्या
  - एकूण सुरक्षा ऑडिट नोंदी (Audit Logs Count)

---

### २. संस्था व्यवस्थापन (Multi-Organization Control)
* **नवीन संस्था ऑनबोर्डिंग (Onboard New Org):**
  - मंडळाचे नाव (उदा. 'श्री शिवछत्रपती सार्वजनिक उत्सव मंडळ')
  - युनिक ओळख (Slug Identifier - उदा. `shiv-chhatrapati-mandal`)
  - जिल्हा, तालुका, गाव आणि नोंदणीकृत पत्ता
  - संस्था स्थिती: **Active** किंवा **Inactive / Archived**
* **संपादित करणे (Edit):** मंडळाचे नाव, संपर्क व्यक्ती, बँक तपशील किंवा स्थिती बदलणे.
* **आर्काइव्ह / डिलिट (Archive):** निष्क्रिय संस्था तात्पुरती गोठवणे किंवा सुरक्षितपणे काढणे.

---

### ३. गट व प्रभाग व्यवस्थापन (Group / Ward Management)
* प्रत्येक मंडळाच्या अंतर्गत भौगोलिक किंवा प्रशासकीय गट तयार करणे:
  - उदा. प्रभाग क्र. १, बाजारपेठ विभाग, स्टेशन रोड, इत्यादी.
* एका क्लिकवर संबंधित संस्थेचे गट फिल्टर करून पाहणे.

---

### ४. केंद्रीय वापरकर्ते व्यवस्थापन (Global User Directory)
* ॲपमधील सर्व वापरकर्त्यांचा एकाच ठिकाणी शोध (Search by Name, Phone, Email).
* **रोल फिल्टर:** सुपर ॲडमिन, संस्था ॲडमिन, खजिनदार, संकलक आणि सामान्य नागरिक (Admins, Treasurers, Collectors, Citizens).
* **वापरकर्ता नियंत्रण:**
  - वापरकर्त्याचे पद बदलणे (Promote / Demote).
  - वापरकर्त्याला ब्लॉक / अनब्लॉक करणे (Lock / Unlock User Account).
  - अनधिकृत किंवा खोटे खाते कायमस्वरूपी डिलीट करणे.

---

### ५. भूमिका व्यवस्थापन (Dynamic RBAC Roles)
* सिस्टीममध्ये डीफॉल्ट रोल्स आणि कस्टम रोल्सचे व्यवस्थापन:
  - `superAdmin`: सर्वोच्च प्रशासक (`permissions: ["*"]`)
  - `orgAdmin`: संस्था प्रशासक
  - `treasurer`: खजिनदार (कॅश पडताळणी व खर्च मंजुरी)
  - `collector`: संकलक (घरोघरी जाऊन वर्गणी गोळा करणे)
  - `viewer`: फक्त पाहण्याचा अधिकार (Read-Only)
  - `citizen`: देणगीदार / नागरिक
* **कस्टम रोल निर्मिती:** विशिष्ट जबाबदाऱ्यांसाठी नवीन रोल तयार करून त्यास विशिष्ट परवानग्या जोडणे.

---

### ६. परवानग्या नियंत्रण (Granular Permissions Matrix)
सुपर ॲडमिन खालील सर्व परवानग्या चालू/बंद करू शकतो:
| कोड (Code) | मॉड्यूल | कृती (Action) | विवरण |
| :--- | :--- | :--- | :--- |
| `campaigns.manage` | Campaigns | Create/Edit/Close | मोहीम तयार करणे व बंद करणे |
| `collections.create` | Collections | Create | वर्गणी पावती तयार करणे |
| `collections.cancel` | Collections | Cancel | पावती रद्द करणे (उच्च सुरक्षा अधिकार) |
| `handovers.confirm` | Handovers | Confirm | जमा झालेली कॅश स्वीकारणे |
| `expenses.approve` | Expenses | Approve | खर्चाचे बिल मंजूर करणे |
| `users.manage` | Users | Status/Block | वापरकर्ता सक्रिय/निष्क्रिय करणे |
| `roles.manage` | Roles | Manage | भूमिका व परवानग्या बदलणे |
| `organizations.manage` | Organizations | CRUD | नवीन संस्था तयार करणे (Super Admin Only) |

---

### ७. भूमिका वाटप (Role Assignment & Transfers)
* एखाद्या कार्यकर्त्याला एका संस्थेतून दुसऱ्या संस्थेत किंवा नवीन पदावर नियुक्त करणे.
* कार्यकर्त्याला विशिष्ट प्रभागांचा (Assigned Groups) प्रभार देणे.

---

### ८. पदानुक्रम रचना मॅपिंग (Hierarchy Mapping)
* पूर्ण सिस्टीमची साखळी पाहणे:
  $$\text{Organization} \longrightarrow \text{Group/Ward} \longrightarrow \text{Collector} \longrightarrow \text{Households}$$
* कोणत्या कार्यकर्त्याकडे कोणत्या गल्लीतील किती कुटुंबे सोपवली आहेत याचे थेट मॅपिंग.

---

### ९. केंद्रीय जोडणी विनंत्या (Join Requests Monitoring)
* कोणत्याही मंडळासाठी कार्यकर्त्यांनी किंवा नागरिकांनी पाठवलेल्या विनंत्या एकाच स्क्रीनवर दिसतात.
* सुपर ॲडमिन कोणत्याही मंडळाच्या वतीने थेट विनंती मंजूर (Approve) किंवा नामंजूर (Reject) करू शकतो.

---

### १०. केंद्रीय वर्गणी व खर्च नियंत्रण (Collections & Expenses Oversight)
* सर्व संस्थांच्या सर्व पावत्यांची (Receipts) रिअल-टाइम यादी.
* संशयास्पद किंवा चुकीची पावती आढळल्यास तपासणी व कॅन्सलेशन लॉग तपासणे.
* खर्च पडताळणी: कोणत्या संस्थेने कोणत्या हेडखाली (मंडप, साऊंड, पूजा) किती खर्च केला ते पाहणे.

---

### ११. ऑडिट लॉग्स आणि सुरक्षा (Audit Logs & Security Trail)
* सिस्टीममधील प्रत्येक संशयास्पद किंवा महत्त्वाची कृती वेळेसह नोंदवली जाते:
  - लॉगिन / लॉगआउट नोंदी
  - भूमिका बदल (Role escalation)
  - पावती रद्द केल्याची तारीख, वेळ, युजर आणि कारण
  - बँक किंवा QR कोड बदलल्याची नोंद

---

### १२. खात्याची स्थिती व सदस्यता (Account Status & Multi-Tenancy)
* प्रत्येक मंडळाचे सदस्यत्व (Subscription / License Status):
  - **Active:** सर्व सुविधा सुरळीत चालू.
  - **Trial:** चाचणी कालावधी.
  - **Suspended / Locked:** नियमांचे उल्लंघन किंवा उत्सव संपल्यामुळे व्यवहार गोठवणे (Lock financial transactions).

---

### १३. सिस्टीम व ॲप्लिकेशन सेटिंग्ज (System Settings)
* **SMS Gateway & WhatsApp Business API:** पावती मेसेज पाठवण्याच्या सर्व्हरची स्थिती.
* **ई-मेल OTP प्रमाणीकरण (Email OTP Service):** ॲपमधील लॉगिन सुरक्षेचे नियम.
* **सुपर ॲडमिन सुरक्षा:** सुपर ॲडमिन खात्यासाठी 2-फॅक्टर ऑथेंटिकेशन (2FA) पर्याय.

---

## ३. सुपर ॲडमिनसाठी आपत्कालीन SOP (Emergency Protocols)

### ১. डुप्लिकेट किंवा चुकीच्या सुपर ॲडमिन खात्यांचे नियंत्रण:
* सिस्टीममध्ये केवळ अधिकृत मुख्य सुपर ॲडमिन खाते सुरक्षित राहते (`phone: 9699342811` / `usr_ritesh`).
* चुकून दुसऱ्या कोणाला सुपर ॲडमिन रोल मिळाला असल्यास सिस्टीम आपोआप त्याला `orgAdmin` वर सुरक्षितपणे रीमॅप करते.

### २. गैरव्यवहार आढळल्यास संस्था लॉक करणे:
1. **Organizations** किंवा **Account Status** मॉड्यूलमध्ये जा.
2. संबंधित संस्था निवडा.
3. स्टेटस **"Suspended"** वर सेट करा.
4. यामुळे त्या संस्थेचे सर्व कलेक्शन आणि एक्सपेंस त्वरित बंद होतात.

### ३. पावती कॅन्सलेशन पडताळणी:
1. **Audit Logs** किंवा **Collections** विभागात जा.
2. 'Cancelled' फिल्टर निवडा.
3. कोणत्या कार्यकर्त्याने आणि कोणत्या कारणास्तव पावती रद्द केली ते तपासा.

---

## ४. तांत्रिक रचना (Technical Architecture)

* **फ्रंटएंड (Frontend):** Flutter (Dart) - Responsive Desktop/Tablet Rail & Mobile Drawer Support (`SuperAdminScreen`).
* **बॅकएंड (Backend):** Python FastAPI + Pydantic Models.
* **डेटाबेस (Database):** Supabase PostgreSQL (Row Level Security & RBAC Enforced).
* **ऑथेंटिकेशन (Auth):** Supabase Auth + Email OTP + Role Claims.

---
*दस्तऐवज तयार केले: वर्गणी ॲप आर्किटेक्चर टीम*
