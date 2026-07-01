"""
Battery monitoring dummy data generator.

Publishes simulated EV battery pack data to the MQTT broker
on the topic expected by the Flutter app (data/monitoring).

Usage:
  python simulator/dummy_generator.py

Optional env vars (or edit defaults below):
  MQTT_HOST, MQTT_USERNAME, MQTT_PASSWORD
"""

import json
import os
import random
import time

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("Missing paho-mqtt. Install with: pip install paho-mqtt")
    raise SystemExit(1)

BROKER = os.getenv("MQTT_HOST", "mqtt.openioe.in")
PORT = 1883
USERNAME = os.getenv("MQTT_USERNAME", "CQmGJZRH175gMHRudHR92mDR5")
PASSWORD = os.getenv("MQTT_PASSWORD", "lXOH762CaZvMm5Nfmfi9cCmAR")
TOPIC = "data/monitoring"

client = mqtt.Client(client_id="dummy_bms_generator")
client.username_pw_set(USERNAME, PASSWORD)

print(f"Connecting to {BROKER}:{PORT}...")
client.connect(BROKER, PORT)
print("Connected! Publishing to", TOPIC)

soc1 = 100.0
soc2 = 95.0

while True:
    payload = {
        "EVID": "EV0001",
        "1": {
            "V": round(random.uniform(47.8, 48.8), 2),
            "I": round(random.uniform(8, 15), 2),
            "SoC": round(soc1, 1),
        },
        "2": {
            "V": round(random.uniform(47.8, 48.8), 2),
            "I": round(random.uniform(8, 15), 2),
            "SoC": round(soc2, 1),
        },
    }

    client.publish(TOPIC, json.dumps(payload), qos=1)
    print(json.dumps(payload, indent=4))

    soc1 -= random.uniform(0.05, 0.15)
    soc2 -= random.uniform(0.05, 0.15)

    if soc1 < 20:
        soc1 = 100
    if soc2 < 20:
        soc2 = 95

    time.sleep(1)
