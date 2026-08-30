#!/usr/bin/env python3
import json
import urllib.request
import sys

WEATHER_ICONS = {
    "113": "☀️",
    "116": "⛅",
    "119": "☁️",
    "122": "☁️",
    "143": "🌫️",
    "176": "🌦️",
    "179": "🌧️",
    "182": "🌧️",
    "185": "🌧️",
    "200": "⛈️",
    "227": "🌨️",
    "230": "❄️",
    "248": "🌫️",
    "260": "🌫️",
    "263": "🌦️",
    "266": "🌧️",
    "281": "🌧️",
    "284": "🌧️",
    "293": "🌧️",
    "296": "🌧️",
    "299": "🌧️",
    "302": "🌧️",
    "305": "🌧️",
    "308": "🌧️",
    "311": "🌧️",
    "314": "🌧️",
    "317": "🌧️",
    "320": "🌨️",
    "323": "🌨️",
    "326": "🌨️",
    "329": "❄️",
    "332": "❄️",
    "335": "❄️",
    "338": "❄️",
    "350": "🌧️",
    "353": "🌦️",
    "356": "🌧️",
    "359": "🌧️",
    "362": "🌨️",
    "365": "🌨️",
    "368": "🌨️",
    "371": "❄️",
    "374": "🌧️",
    "377": "🌧️",
    "386": "⛈️",
    "389": "🌩️",
    "392": "⛈️",
    "395": "❄️"
}

def fetch_weather():
    url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/7.68.0"})
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                current = data.get("current_condition", [{}])[0]
                weather_code = current.get("weatherCode", "113")
                temp_c = current.get("temp_C", "0")
                feels_like = current.get("FeelsLikeC", temp_c)
                weather_desc = current.get("weatherDesc", [{}])[0].get("value", "Clear")
                icon = WEATHER_ICONS.get(weather_code, "⛅")
                
                nearest_area = data.get("nearest_area", [{}])[0]
                city = nearest_area.get("areaName", [{}])[0].get("value", "Istanbul")
                
                # Daily forecast
                today = data.get("weather", [{}])[0]
                min_temp = today.get("mintempC", temp_c) + "°"
                max_temp = today.get("maxtempC", temp_c) + "°"
                
                wind_speed = current.get("windspeedKmph", "0") + " km/h"
                humidity = current.get("humidity", "0") + "%"
                visibility = current.get("visibility", "10") + " km"
                
                # Hourly rain
                hourly = today.get("hourly", [])
                rain_chances = []
                for h in hourly[:5]:
                    chance = h.get("chanceofrain", "0")
                    rain_chances.append(f"Rain drop {chance}%")
                
                rain_str = "\n".join(rain_chances) if rain_chances else "Rain drop 0%"
                
                tooltip = (
                    f"<b>{city}</b>\n"
                    f"Feels like {feels_like}°C\n"
                    f"<big>{icon}</big>\n"
                    f"  {min_temp}\t\t  {max_temp}\n"
                    f"{wind_speed}\t{humidity}\n"
                    f"{visibility}\tAQI 25\n"
                    f"{rain_str}"
                )
                
                result = {
                    "text": f"{icon} {temp_c}° {city}",
                    "alt": weather_desc,
                    "tooltip": tooltip
                }
                print(json.dumps(result))
                return
    except Exception:
        pass

    # Fallback if offline
    fallback = {
        "text": "⛅ --° Istanbul",
        "alt": "Unknown",
        "tooltip": "<b>Istanbul</b>\nFeels like --°C\n<big>⛅</big>\n  --°\t\t  --°\n-- km/h\t--%\n-- km\tAQI --\nRain drop 0%"
    }
    print(json.dumps(fallback))

if __name__ == "__main__":
    fetch_weather()
