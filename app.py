from flask import Flask, request, jsonify
import requests
import pandas as pd
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string
import os

app = Flask(__name__)

# --- Função para pegar dados históricos NASA POWER para um dia específico ---
def get_historical_data_day(lat, lon, month_day, years=range(2013, 2024)):
    all_data = []
    for year in years:
        date_str = f"{year}{month_day}"  # YYYYMMDD
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
            print(f"Aviso: não foi possível obter dados para {year}: {e}")
    if not all_data:
        return pd.DataFrame()
    return pd.concat(all_data)

# --- Função para calcular probabilidades híbridas e humanizar ---
def calculate_probabilities_humanized(df):
    total_days = len(df)
    if total_days == 0:
        return {
            "message": "⚠️ Sem dados históricos disponíveis para este dia."
        }

    # Thresholds híbridos
    temp_mean = df["temperature"].mean()
    temp_std = df["temperature"].std()
    hot_thr = temp_mean + 1.5 * temp_std
    cold_thr = temp_mean - 1.5 * temp_std
    wind_thr = df["wind"].quantile(0.9)
    wet_thr = df["precip"].quantile(0.9)

    # Probabilidades
    prob_hot = (df["temperature"] > hot_thr).sum() / total_days * 100
    prob_cold = (df["temperature"] < cold_thr).sum() / total_days * 100
    prob_windy = (df["wind"] > wind_thr).sum() / total_days * 100
    prob_wet = (df["precip"] > wet_thr).sum() / total_days * 100

    # Médias
    avg_temp = df["temperature"].mean()
    avg_wind = df["wind"].mean()
    avg_precip = df["precip"].mean()

    # Mensagem humanizada
    message = (
        f"🌡️ Temperatura média histórica: {avg_temp:.1f}°C\n"
        f"💨 Velocidade média do vento: {avg_wind:.1f} m/s\n"
        f"🌧️ Precipitação média: {avg_precip:.1f} mm/dia\n\n"
        f"Probabilidades para este dia baseado no histórico:\n"
        f"🔥 Muito quente: {prob_hot:.1f}% (>{hot_thr:.1f}°C)\n"
        f"❄️ Muito frio: {prob_cold:.1f}% (<{cold_thr:.1f}°C)\n"
        f"💨 Muito ventoso: {prob_windy:.1f}% (>{wind_thr:.1f} m/s)\n"
        f"🌧️ Muito úmido: {prob_wet:.1f}% (>{wet_thr:.1f} mm/dia)"
    )

    return {
        "probabilities": {
            "very_hot": prob_hot,
            "very_cold": prob_cold,
            "very_windy": prob_windy,
            "very_wet": prob_wet
        },
        "averages": {
            "temperature": avg_temp,
            "wind": avg_wind,
            "precip": avg_precip
        },
        "thresholds": {
            "very_hot": hot_thr,
            "very_cold": cold_thr,
            "very_windy": wind_thr,
            "very_wet": wet_thr
        },
        "message": message
    }

# --- Endpoint principal ---
@app.route("/weather_probability", methods=["POST"])
def weather_probability():
    data = request.get_json()
    lat = data["latitude"]
    lon = data["longitude"]
    date_str = data["date"]  # YYYYMMDD

    # Qualidade dos dados
    target_year = int(date_str[:4])
    today_year = datetime.now().year
    delta_years = abs(target_year - today_year)
    if delta_years == 0:
        quality_msg = "Alta confiabilidade (dados recentes)."
    elif delta_years <= 2:
        quality_msg = "Boa confiabilidade (pequena distância temporal)."
    else:
        quality_msg = "⚠️ Confiabilidade reduzida para datas muito distantes do presente."

    # Histórico para o mesmo dia
    month_day = date_str[4:]
    df_hist = get_historical_data_day(lat, lon, month_day)
    stats = calculate_probabilities_humanized(df_hist)
    stats["quality_message"] = quality_msg

    return jsonify(stats)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))  # 5000 para teste local
    app.run(host="0.0.0.0", port=port, debug=True)


