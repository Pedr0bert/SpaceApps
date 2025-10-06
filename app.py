from flask import Flask, request, jsonify
from flask_cors import CORS 
import requests 
import pandas as pd 
from datetime import datetime  
import os  

# --- Initialize the Flask Application ---
app = Flask(__name__)
# Enable CORS for the entire app, allowing requests from any origin.
# This is crucial for your web-based Flutter app to communicate with this API.
CORS(app)

# --- Function to fetch historical weather data from NASA POWER for a specific day of the year ---
def get_historical_data_day(lat, lon, month_day, years=range(2013, 2024)):
    """
    Fetches daily weather data for a given latitude, longitude, and month/day
    across a range of years from the NASA POWER API.
    """
    all_data = []  # A list to store the data for each year

    # Loop through each year in the specified range
    for year in years:
        date_str = f"{year}{month_day}"  # Format the date as YYYYMMDD
        # Construct the API request URL with the specified parameters
        url = (
            f"https://power.larc.nasa.gov/api/temporal/daily/point"
            f"?parameters=T2M,WS2M,PRECTOTCORR&start={date_str}&end={date_str}"
            f"&latitude={lat}&longitude={lon}&community=AG&format=JSON"
        )
        try:
            # Make the GET request to the NASA API and parse the JSON response
            resp = requests.get(url, timeout=30).json()
            data = resp["properties"]["parameter"]

            # Create a pandas DataFrame from the received data
            df = pd.DataFrame({
                "temperature": list(data["T2M"].values()),
                "wind": list(data["WS2M"].values()),
                "precip": list(data["PRECTOTCORR"].values())
            }, index=pd.to_datetime(list(data["T2M"].keys())))
            all_data.append(df)
        except Exception as e:
            # Print a warning if data for a specific year cannot be retrieved
            print(f"Warning: could not retrieve data for {year}: {e}")

    # If no data was collected, return an empty DataFrame
    if not all_data:
        return pd.DataFrame()

    # Concatenate all the yearly data into a single DataFrame and return it
    return pd.concat(all_data)

# --- Function to calculate weather probabilities and generate a human-readable summary ---
def calculate_probabilities_humanized(df):
    """
    Analyzes the historical weather DataFrame to calculate probabilities of
    extreme weather conditions (hot, cold, windy, wet).
    """
    total_days = len(df)
    # If the DataFrame is empty, return a message indicating no data is available
    if total_days == 0:
        return {
            "message": "⚠️ No historical data available for this day."
        }

    # --- Calculate Thresholds for Extreme Weather ---
    # For temperature, "extreme" is defined as 1.5 standard deviations from the mean
    temp_mean = df["temperature"].mean()
    temp_std = df["temperature"].std()
    hot_thr = temp_mean + 1.5 * temp_std
    cold_thr = temp_mean - 1.5 * temp_std
    # For wind and precipitation, "extreme" is defined as the top 10% (90th percentile)
    wind_thr = df["wind"].quantile(0.9)
    wet_thr = df["precip"].quantile(0.9)

    # --- Calculate Probabilities ---
    # Calculate the percentage of historical days that exceeded these thresholds
    prob_hot = (df["temperature"] > hot_thr).sum() / total_days * 100
    prob_cold = (df["temperature"] < cold_thr).sum() / total_days * 100
    prob_windy = (df["wind"] > wind_thr).sum() / total_days * 100
    prob_wet = (df["precip"] > wet_thr).sum() / total_days * 100

    # --- Calculate Averages ---
    avg_temp = df["temperature"].mean()
    avg_wind = df["wind"].mean()
    avg_precip = df["precip"].mean()

    # --- Create a Human-Readable Message ---
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

    # --- Return all calculated data in a structured dictionary ---
    return {
        "probabilities": {"very_hot": prob_hot, "very_cold": prob_cold, "very_windy": prob_windy, "very_wet": prob_wet},
        "averages": {"temperature": avg_temp, "wind": avg_wind, "precip": avg_precip},
        "thresholds": {"very_hot": hot_thr, "very_cold": cold_thr, "very_windy": wind_thr, "very_wet": wet_thr},
        "message": message
    }

# --- Main API Endpoint ---
@app.route("/weather_probability", methods=["POST", "OPTIONS"])
def weather_probability():
    """
    The main API endpoint that receives location and date, fetches historical data,
    calculates probabilities, and returns the result.
    """
    # Handle CORS preflight requests sent by browsers
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200

    # Validate the incoming JSON request body
    try:
        data = request.get_json()
        if not data or not all(k in data for k in ["latitude", "longitude", "date"]):
            return jsonify({"error": "Missing required fields: latitude, longitude, date"}), 400

        lat = data["latitude"]
        lon = data["longitude"]
        date_str = data["date"]
    except Exception as e:
        return jsonify({"error": "Invalid request body. Ensure it is valid JSON."}), 400

    # --- Data Quality Assessment ---
    # Determine the reliability of the prediction based on the distance from the present
    target_year = int(date_str[:4])
    today_year = datetime.now().year
    delta_years = abs(target_year - today_year)
    if delta_years == 0:
        quality_msg = "High reliability (recent date)."
    elif delta_years <= 2:
        quality_msg = "Good reliability (small temporal distance)."
    else:
        quality_msg = "⚠️ Reduced reliability for dates far from the present."

    # --- Fetch and Process Data ---
    month_day = date_str[4:]  # Extract MMSS from the date string
    df_hist = get_historical_data_day(lat, lon, month_day)  # Fetch historical data
    stats = calculate_probabilities_humanized(df_hist)  # Calculate stats
    stats["quality_message"] = quality_msg  # Add the quality message to the results

    # Return the final statistics as a JSON response
    return jsonify(stats)

# --- Entry point for running the application ---
if __name__ == "__main__":
    # Get the port from the environment variable 'PORT', defaulting to 5000 for local testing
    port = int(os.environ.get("PORT", 5000))
    # Run the Flask app. In production (like on Render), a Gunicorn server will be used instead.
    app.run(host="0.0.0.0", port=port)


