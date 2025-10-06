# TOBI (Temperature, Observation & Behavior Index)

TOBI (Temperature, Observation & Behavior Index) is a project developed by **Team BOREALIS** for the **NASA Space Apps Challenge 2025**, under the challenge **“Will It Rain on My Parade?”**.

## Access

**website:** https://smlesilva.github.io/TOBI/
apk(download): https://github.com/Pedr0bert/TOBI/releases/download/app/TOBI.1.apk
---

## What does it do and how does it work?

TOBI provides weather probability analysis for outdoor event planning.  
It uses **NASA POWER API** datasets (2013–2024) to calculate the likelihood of extreme weather conditions—such as very hot, very cold, very windy, or very wet days—based on historical trends for a given location and date.  

Its analysis is done using the past dates matching the one selected.  
For example, if someone selects **14/05/2026**, TOBI searches all **14/05** dates from **2013 to 2024** and calculates probabilities based on those records.

---

## 🧠 Backend (Python Flask)

- Endpoint `/weather_probability` accepts latitude, longitude, and date.  
- Fetches NASA POWER data.  
- Computes averages, standard deviations, and quantiles.  
- Defines thresholds for extreme conditions (e.g., very hot = T > mean + 1.5×SD).  
- Generates JSON responses with probabilities, thresholds, averages, and a natural-language message.

---

## 💻 Frontend (Flutter + HTML/CSS/JS)

- Provides a responsive interface for user input.  
- Sends requests to the backend and displays results.  
- Uses icons and color coding for clarity.

---

## 🌍 Benefits

- Helps organizers plan outdoor events with reduced weather risk.  
- Makes satellite-based NASA datasets accessible and useful to the general public.  
- Provides probability-based insights instead of raw weather data.  
- Adds a data reliability layer, warning users when historical data is less relevant.

---

## 🎯 Intended Impact

The project bridges scientific meteorological datasets with everyday usability, empowering individuals, communities, and organizations to make informed decisions about weather-sensitive activities.

---

## 🧰 Tools, Languages, and Software

- **Backend:** Python, Flask, RESTful APIs (JSON)  
- **Frontend:** Flutter, HTML, CSS, JavaScript  
- **Data Source:** NASA POWER API (`/temporal/daily/point`)
  - `T2M` (Temperature at 2m)  
  - `WS2M` (Wind speed at 2m)  
  - `PRECTOTCORR` (Corrected daily precipitation)

---

## 🎨 Creativity

- Converts technical climate data into clear, human-friendly insights.  
- Uses statistical modeling + visualization to present probabilities.  
- Introduces threshold-based categorization of weather extremes.  
- Designed for both usability and educational impact.

---

## 👥 Team Considerations

- **Accuracy:** Ensuring reliability by referencing recent years’ data.  
- **Accessibility:** Intuitive UI with simple visuals and messages.  
- **Scalability:** Future roadmap includes machine learning, map-based visualizations, and real-time notifications.  
- **User trust:** Reliability scoring helps users judge confidence in results.

---

## ✨ In short

TOBI demonstrates how open NASA datasets can be transformed into a practical, educational, and user-friendly decision-making tool, making climate science accessible for real-world event planning.

