import json
import time
import random
import threading

try:
    import paho.mqtt.client as mqtt
except ImportError:
    print("Missing paho-mqtt. Install with: pip install paho-mqtt")
    raise SystemExit(1)

MQTT_BROKER = "localhost"
MQTT_PORT = 1883
PUBLISH_INTERVAL = 2  # seconds

EVS = {
    "EV001": {"soc": 85.0, "voltage": 355.2, "current": -12.5},
    "EV002": {"soc": 62.0, "voltage": 348.7, "current": 8.3},
    "EV003": {"soc": 23.0, "voltage": 335.1, "current": -45.0},
}


def simulate(ev_id, state):
    state["soc"] += random.uniform(-0.5, 0.3)
    state["soc"] = max(0, min(100, state["soc"]))
    noise = random.uniform(-0.5, 0.5)
    state["voltage"] += noise
    state["current"] += random.uniform(-2, 2)
    state["current"] = max(-80, min(80, state["current"]))

    payload = json.dumps({
        "id": ev_id,
        "soc": round(state["soc"], 1),
        "voltage": round(state["voltage"], 1),
        "current": round(state["current"], 1),
    })
    return payload


def on_connect(client, userdata, flags, rc, reason=None):
    if rc == 0:
        print(f"Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
    else:
        print(f"Connection failed (RC={rc})")


def main():
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect

    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
    except ConnectionRefusedError:
        print(f"Could not connect to {MQTT_BROKER}:{MQTT_PORT}")
        print("Make sure Mosquitto (or another broker) is running.")
        print("Quick start: docker run -d -p 1883:1883 eclipse-mosquitto")
        return

    client.loop_start()

    print("BMS Simulator running. Publishing every 2 seconds...")
    print(f"EVs: {', '.join(EVS.keys())}")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            for ev_id, state in EVS.items():
                payload = simulate(ev_id, state)
                topic = f"ev/bms/{ev_id}/telemetry"
                client.publish(topic, payload, qos=1)
                print(f"[{time.strftime('%H:%M:%S')}] {topic} -> {payload}")
            time.sleep(PUBLISH_INTERVAL)
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
