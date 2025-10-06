# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS  # <--- MUDANÇA 1: Importar o CORS
import requests
import pandas as pd
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)  # <--- MUDANÇA 2: Ativar o CORS para toda a sua aplicação

# --- Sua função get_historical_data_day (sem alterações) ---
def get_historical_data_day(lat, lon, month_day, years=range(2013, 2024)):
    all_data = []
    for year in years:
        date_str = f"{year}{month_day}"
        url = (
            f"https://power.larc.nasa.gov/api/temporal/daily/point"
            f"?parameters=T2M,WS2M,PRECTOTCORR&start={date_str}&end={date_str}"
            f"&latitude={lat}&longitude={lon}&community=AG&format=JSON"
        )
        try:
            resp = requests.get(url).json()
            data = resp["properties"]["parameter"]
            df = pd.DataFrame({
                "temperature": list(data["T2M"].values()),
                "wind": list(data["WS2M"].values()),
                "precip": list(data["PRECTOTCORR"].values())
            }, index=pd.to_datetime(list(data["T2M"].keys())))
            all_data.append(df)
        except Exception as e:
            print(f"Warning: could not retrieve data for {year}: {e}")
    if not all_data:
        return pd.DataFrame()
    return pd.concat(all_data)

# --- Sua função calculate_probabilities_humanized (sem alterações) ---
def calculate_probabilities_humanized(df):
    total_days = len(df)
    if total_days == 0:
        return {
            "message": "⚠️ No historical data available for this day."
        }
    
    # ... (resto da sua função sem alterações) ...
    temp_mean = df["temperature"].mean()
    temp_std = df["temperature"].std()
    hot_thr = temp_mean + 1.5 * temp_std
    cold_thr = temp_mean - 1.5 * temp_std
    wind_thr = df["wind"].quantile(0.9)
    wet_thr = df["precip"].quantile(0.9)
    prob_hot = (df["temperature"] > hot_thr).sum() / total_days * 100
    prob_cold = (df["temperature"] < cold_thr).sum() / total_days * 100
    prob_windy = (df["wind"] > wind_thr).sum() / total_days * 100
    prob_wet = (df["precip"] > wet_thr).sum() / total_days * 100
    avg_temp = df["temperature"].mean()
    avg_wind = df["wind"].mean()
    avg_precip = df["precip"].mean()
    message = (
        f"🌡️ Historical average temperature: {avg_temp:.1f}°C\n"
        f"💨 Average wind speed: {avg_wind:.1f} m/s\n"
        f"🌧️ Average precipitation: {avg_precip:.1f} mm/day\n\n"
        f"Probabilities for this day based on historical data:\n"
        f"🔥 Very hot: {prob_hot:.1f}% (>{hot_thr:.1f}°C)\n"
        f"❄️ Very cold: {prob_cold:.1f}% (<{cold_thr:.1f}°C)\n"
        f"💨 Very windy: {prob_windy:.1f}% (>{wind_thr:.1f} m/s)\n"
        f"🌧️ Very wet: {prob_wet:.1f}% (>{wet_thr:.1f} mm/day)"
    )
    return {
        "probabilities": {"very_hot": prob_hot, "very_cold": prob_cold, "very_windy": prob_windy, "very_wet": prob_wet},
        "averages": {"temperature": avg_temp, "wind": avg_wind, "precip": avg_precip},
        "thresholds": {"very_hot": hot_thr, "very_cold": cold_thr, "very_windy": wind_thr, "very_wet": wet_thr},
        "message": message
    }

# --- Main endpoint ---
@app.route("/weather_probability", methods=["POST", "OPTIONS"]) # Adicionado OPTIONS para pre-flight
def weather_probability():
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200

    # <--- MUDANÇA 3: Adicionado tratamento de erros ---
    try:
        data = request.get_json()
        if not data or 'latitude' not in data or 'longitude' not in data or 'date' not in data:
            return jsonify({"error": "Missing required fields: latitude, longitude, date"}), 400

        lat = data["latitude"]
        lon = data["longitude"]
        date_str = data["date"]
    except Exception as e:
        return jsonify({"error": "Invalid request body. Ensure it is valid JSON."}), 400
    # --- Fim da MUDANÇA 3 ---

    # Data quality
    target_year = int(date_str[:4])
    today_year = datetime.now().year
    delta_years = abs(target_year - today_year)
    if delta_years == 0:
        quality_msg = "High reliability (recent date)."
    elif delta_years <= 2:
        quality_msg = "Good reliability (small temporal distance)."
    else:
        quality_msg = "⚠️ Reduced reliability for dates far from the present."

    # Historical data for the same day
    month_day = date_str[4:]
    df_hist = get_historical_data_day(lat, lon, month_day)
    stats = calculate_probabilities_humanized(df_hist)
    stats["quality_message"] = quality_msg

    return jsonify(stats)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port) # debug=True removido por segurança
