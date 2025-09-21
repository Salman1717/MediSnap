# 🩺 MediSnap – AI-Powered Prescription & Medication Assistant  

> Built for **Hack2k Hackathon** sponsored by **GDC Cloud Mumbai**  

## 👥 Team  
- **Aaseem Mhaskar** : [@aaseem22](https://github.com/aaseem22)  
- **Salman Mhaskar** : [@Salman1717](https://github.com/Salman1717)  

---

## 🚨 Problem Statement  
Millions of patients struggle to manage their medications due to:  
- **Unclear Prescriptions** – messy handwriting, complex jargon.  
- **Confusing Instructions** – leading to missed or wrong doses.  
- **Tedious Tracking** – hard to maintain daily logs.  
- **Lack of Information** – poor understanding of side effects and interactions.  

---

## 💡 Our Solution – *MediSnap*  
MediSnap simplifies medication management using **AI + Cloud**.  

**User Story**  
Imagine Jane, who receives a handwritten prescription:  
1. 📸 *She Scans* → Uploads her prescription.  
2. 🤖 *AI Extracts* → Gemini AI reads medicines, dosages, and schedules.  
3. 🗓️ *Smart Schedule* → Doses are auto-added to **Google Calendar** with reminders.  
4. 💬 *Instant Guidance* → Plain-language explanations, health advice, safety alerts.  
5. 🛡️ *Stay Safe* → Side effects and precautions flagged automatically.  

---

## ⚙️ Technical Solution – *Agentic Flow*  
**Sense → Think → Act**  

- **Sense**: User scans/upload prescription.  
- **Think**: Gemini AI extracts medicine details, checks for precautions.  
- **Act**: Generates schedules in Google Calendar + provides insights & tips.  

---

## ✨ Features  
✅ AI Prescription Extraction – scan and parse dosage/frequency.  
✅ Smart Calendar Scheduling – auto reminders in Google Calendar.  
✅ Daily Health Tips – personalized AI-powered insights.  
✅ Safety View – side effect & precaution analysis.  
✅ Radiology Report Analysis – severity assessment + guidance.  
✅ Patient-Friendly UI – built with SwiftUI for simplicity.  

---

## 🛠️ Tech Stack  
- **Frontend**: Swift, SwiftUI (iOS app)  
- **AI Models**: Gemini 2.5 Pro (Vision + Text)  
- **Backend**: Firebase, Google Cloud  
- **Calendar Integration**: Google Calendar API  
- **Data Storage**: Firestore  

---

## 🤖 Use of Gemini API  
- **Extraction** – from scanned prescriptions (Vision)  
- **Guidance** – plain-language explanations, daily tips  
- **Safety Analysis** – detect precautions & side effects  
- **Agentic Flow** – orchestrates end-to-end automation  

---



## 📽️ Demo Video

[Watch the Demo Video](https://drive.google.com/file/d/1eZlJTUVqHeBYZgrNeLp-Iykx5hcB5m8Y/view?usp=sharing)

## 🎞️ Demo  Screenshots

<img width="1170" height="2532" alt="IMG_9675" src="https://github.com/user-attachments/assets/de0f12a9-b544-46f9-a522-23d9abb27745" />

<img width="1170" height="2532" alt="IMG_9671" src="https://github.com/user-attachments/assets/49de0429-92fa-41d4-9444-5d34c96880be" />

<img width="1170" height="2532" alt="IMG_9672" src="https://github.com/user-attachments/assets/c658d45c-fff6-4699-8019-754d8ff3644d" />

<img width="1170" height="2532" alt="IMG_9673" src="https://github.com/user-attachments/assets/3c44bd57-aad6-406d-9724-133d51e1abdf" />

<img width="1170" height="2532" alt="IMG_9670" src="https://github.com/user-attachments/assets/69ba5ac4-46d8-409c-8f26-6fcec93672fb" />

<img width="1170" height="2532" alt="IMG_9669" src="https://github.com/user-attachments/assets/e24de4d1-4201-40b5-9bd1-c669a00ec450" />

<img width="1170" height="2532" alt="IMG_9676" src="https://github.com/user-attachments/assets/35ef6901-7ca3-40cf-badb-9daad06de7a4" />

<img width="1204" height="598" alt="Screenshot 2025-09-21 at 8 15 18 AM" src="https://github.com/user-attachments/assets/b4853702-81b2-4372-89c2-5073c37fe75c" />


---

## 🚀 Getting Started  

### Prerequisites  
- Xcode 15+  
- iOS 18+ device/simulator  
- Firebase project setup  
- Google Cloud APIs (Gemini + Calendar API) enabled  

### Setup  
```bash
# Clone repo
git clone https://github.com/Salman1717/MediSnap.git
cd MediSnap

# Open in Xcode
open MediSnap.xcodeproj
```

1. Add your Firebase **GoogleService-Info.plist**.  
2. Configure **Gemini API Key** in your Xcode environment.  
3. Enable **Google Calendar API** in GCP.  
4. Run the app 🚀  

---

## 📌 Hackathon Context  
This project was built as part of **Hack2k Hackathon** organized by **GDC Cloud Mumbai**.  
Our goal: **empower patients with AI-driven clarity, safety, and ease in medication management**.  

---

## 🙏 Acknowledgements  
- **Gemini AI** for powering vision + text workflows  
- **Firebase & GCP** for backend support  
- **Hack2k & GDC Cloud Mumbai** for the opportunity  
