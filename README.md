# Tumor Track

An AI-assisted mobile healthcare platform that supports brain tumor and breast cancer assessment and care coordination. Patients can upload brain MRI and mammography images for AI-based analysis and receive preliminary, structured reports to support clinical decision-making. Doctors can review reports, communicate with patients, and issue electronic prescriptions, while pharmacists manage prescription fulfillment. The system also includes a drug–drug interaction checking feature to support safer medication workflows.

## Key Features
- Upload brain MRI and breast mammogram images for AI-assisted analysis (decision support)
- Automatic generation of structured medical reports (with confidence scores)
- Secure patient–doctor chat with optional file sharing (e.g., reports)
- Drug–drug interaction checking for oncology medications and co-medications
- E-prescription workflow: doctor issues prescriptions, patient selects a pharmacy, pharmacist fulfills

## Tech Stack (High-level)
- Flutter mobile app (cross-platform)
- Django backend + REST APIs
- Separate AI inference service (REST-based)
- Rule-based drug interaction module

> Disclaimer: AI results are intended for decision support and do not replace professional medical diagnosis.
