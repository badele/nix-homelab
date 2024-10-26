# zigbee2mqtt

## Reset factory

### From terminal
```bash
# Get password from passwordstore tool
export MQTT_Z2M_PASS=$(pass show home/bruno/homelab/mqtt/zigbee2mqtt)

# Scan device
mosquitto_pub -d -h zigbee.adele.im -u zigbee2mqtt -P "${MQTT_Z2M_PASS}" -t zigbee2mqtt/bridge/request/touchlink/scan -m ''

# Identify (blink lamp)
mosquitto_pub -d -h zigbee.adele.im -u zigbee2mqtt -P "${MQTT_Z2M_PASS}" -t zigbee2mqtt/bridge/request/touchlink/identify -m '{"channel":11,"ieee_address":"0x0017880109b265cb"}'

# Factory reset
mosquitto_pub -d -h zigbee.adele.im -u zigbee2mqtt -P "${MQTT_Z2M_PASS}" -t zigbee2mqtt/bridge/request/touchlink/factory_reset -m '{"channel":11,"ieee_address":"0x0017880109b265cb"}'
```
## State values

### From terminal

```bash
export MQTT_Z2M_PASS=$(pass show home/bruno/homelab/mqtt/zigbee2mqtt)
mosquitto_pub -d -h zigbee.adele.im -u zigbee2mqtt -P "${MQTT_Z2M_PASS}" -t zigbee2mqtt/desk-left-light/set -m '{"state":"OFF"}' # ON|OFF|TOGGLE
```

## viewing MQTT message

```bash
export MQTT_Z2M_PASS=$(pass show home/bruno/homelab/mqtt/zigbee2mqtt)
mqttui -b mqtt://mqtt.adele.im -u zigbee2mqtt --password "${MQTT_Z2M_PASS}"
```
