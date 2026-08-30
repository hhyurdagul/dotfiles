#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import sys

WEATHER_ICONS = {
    "113": "󰖙",  # Sunny / Clear
    "116": "󰖕",  # Partly cloudy
    "119": "󰖐",  # Cloudy
    "122": "󰖐",  # Overcast
    "143": "󰖑",  # Mist / Fog
    "176": "󰖗",  # Patchy rain possible
    "179": "󰖘",  # Patchy snow possible
    "182": "󰖘",  # Patchy sleet possible
    "185": "󰖘",  # Patchy freezing drizzle possible
    "200": "󰙾",  # Thundery outbreaks possible
    "227": "󰖘",  # Blowing snow
    "230": "󰖘",  # Blizzard
    "248": "󰖑",  # Fog
    "260": "󰖑",  # Freezing fog
    "263": "󰖗",  # Patchy light drizzle
    "266": "󰖗",  # Light drizzle
    "281": "󰖘",  # Freezing drizzle
    "284": "󰖘",  # Heavy freezing drizzle
    "293": "󰖗",  # Patchy light rain
    "296": "󰖗",  # Light rain
    "299": "󰖖",  # Moderate rain at times
    "302": "󰖖",  # Moderate rain
    "305": "󰖖",  # Heavy rain at times
    "308": "󰖖",  # Heavy rain
    "311": "󰖘",  # Light freezing rain
    "314": "󰖘",  # Moderate or Heavy freezing rain
    "317": "󰖘",  # Light sleet
    "320": "󰖘",  # Moderate or heavy sleet
    "323": "󰖘",  # Patchy light snow
    "326": "󰖘",  # Light snow
    "329": "󰖘",  # Patchy moderate snow
    "332": "󰖘",  # Moderate snow
    "335": "󰖘",  # Patchy heavy snow
    "338": "󰖘",  # Heavy snow
    "350": "󰖘",  # Ice pellets
    "353": "󰖗",  # Light rain shower
    "356": "󰖖",  # Moderate or heavy rain shower
    "359": "󰖖",  # Torrential rain shower
    "362": "󰖘",  # Light sleet showers
    "365": "󰖘",  # Moderate or heavy sleet showers
    "368": "󰖘",  # Light snow showers
    "371": "󰖘",  # Moderate or heavy snow showers
    "374": "󰖘",  # Light showers of ice pellets
    "377": "󰖘",  # Moderate or heavy showers of ice pellets
    "386": "󰙾",  # Patchy light rain with thunder
    "389": "󰙾",  # Moderate or heavy rain with thunder
    "392": "󰙾",  # Patchy light snow with thunder
    "395": "󰙾",  # Moderate or heavy snow with thunder
}

def fetch_weather():
    url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (compatible; QuickshellBar/1.0)"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data
    except Exception as e:
        return None

def main():
    data = fetch_weather()
    if not data or "current_condition" not in data or not data["current_condition"]:
        print(json.dumps({"text": "", "alt": "", "tooltip": ""}))
        return

    cur = data["current_condition"][0]
    weather_code = cur.get("weatherCode", "113")
    icon = WEATHER_ICONS.get(weather_code, "󰖐")
    temp_c = cur.get("temp_C", "0")
    feels_like = cur.get("FeelsLikeC", temp_c)
    desc = cur.get("weatherDesc", [{}])[0].get("value", "Clear")
    humidity = cur.get("humidity", "0")
    wind = cur.get("windspeedKmph", "0")
    visibility = cur.get("visibility", "10")
    
    # Location
    area = "Local"
    if "nearest_area" in data and data["nearest_area"]:
        nearest = data["nearest_area"][0]
        area_name = nearest.get("areaName", [{}])[0].get("value", "")
        country = nearest.get("country", [{}])[0].get("value", "")
        if area_name:
            area = f"{area_name}"

    # Min/Max from today's forecast
    min_temp = temp_c
    max_temp = temp_c
    rain_hourly = []
    if "weather" in data and data["weather"]:
        today = data["weather"][0]
        min_temp = today.get("mintempC", temp_c)
        max_temp = today.get("maxtempC", temp_c)
        if "hourly" in today:
            for h in today["hourly"]:
                chance = h.get("chanceofrain", "0")
                rain_hourly.append(f"Rain drop {chance}%")

    text_bar = f"{icon} {temp_c}° {area}"
    
    tooltip_lines = [
        f"<b>{area}</b>",
        f"<big>{icon}</big>",
        f"Feels like {feels_like}°C",
        f" {min_temp}°C\t\t {max_temp}°C",
        f"{wind} km/h\t{humidity}%",
        f"{visibility} km\tAQI 35"
    ]
    tooltip_lines.extend(rain_hourly[:6])
    tooltip_str = "\n".join(tooltip_lines)

    result = {
        "text": text_bar,
        "alt": desc,
        "tooltip": tooltip_str
    }
    print(json.dumps(result))

if __name__ == "__main__":
    main()
