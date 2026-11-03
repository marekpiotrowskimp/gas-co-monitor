import gc
import machine
import time
#import ina219
from machine import Pin, I2C, ADC
import lcd_2004
from ble import BLESimplePeripheral
import bluetooth
from ble_advertising import advertising_payload
import network
import urequests as requests
import ntptime
import socket
import ujson
from config import WIFI_SSID, WIFI_PASSWORD, NTFY_TOPIC, NTFY_TOKEN

# WiFi Configuration
WIFI_CONNECT_TIMEOUT_MS = 10000
WIFI_MIN_RETRY_INTERVAL_MS = 5000
WIFI_MAX_RETRY_INTERVAL_MS = 60000

# NTP/Clock Configuration
NTP_HOST = "pool.ntp.org"
NTP_SYNC_INTERVAL_MS = 3600000  # resync co 1h
TIMEZONE_OFFSET_WINTER = 1  # CET
TIMEZONE_OFFSET_SUMMER = 2  # CEST

# Alert Configuration (ntfy)
NTFY_SERVER = "https://ntfy.sh"
NTFY_TIMEOUT_S = 5
ALERT_REPEAT_MS = 30000    # przypomnienie co 30s, dopóki alarm trwa
ALERT_RETRY_MS = 10000     # ponowienie po nieudanej wysyłce
ALERT_CLEAR_MS = 10000     # alarm musi ustać na 10s, zanim wyślemy "ustąpił"

# UDP Configuration
UDP_AIR_PORT = 5000       # nasłuch danych powietrza (Xiao -> my)
UDP_CO2_PORT = 5002       # broadcast CO/Gaz (my -> świat)
UDP_BROADCAST_IP = "255.255.255.255"
UDP_BROADCAST_INTERVAL_MS = 10000
AIR_DATA_STALE_MS = 60000

# Custom character definitions - WiFi only
# Animation frames (connecting) - growing waves
CHAR_WIFI_1 = [0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00]  # kropka
CHAR_WIFI_2 = [0x00, 0x00, 0x04, 0x00, 0x04, 0x00, 0x00, 0x00]  # 1 fala
CHAR_WIFI_3 = [0x00, 0x04, 0x0A, 0x00, 0x04, 0x00, 0x00, 0x00]  # 2 fale
CHAR_WIFI_4 = [0x04, 0x0A, 0x11, 0x00, 0x04, 0x00, 0x00, 0x00]  # 3 fale
# Connected - checkmark
CHAR_WIFI_OK = [0x00, 0x01, 0x02, 0x02, 0x14, 0x08, 0x00, 0x00]
# Disconnected/waiting - hourglass (klepsydra)
CHAR_WIFI_WAIT = [0x1F, 0x0E, 0x04, 0x04, 0x0E, 0x1F, 0x00, 0x00]

# Character slot assignments
SLOT_WIFI_1 = 0
SLOT_WIFI_2 = 1
SLOT_WIFI_3 = 2
SLOT_WIFI_4 = 3
SLOT_WIFI_OK = 4
SLOT_WIFI_WAIT = 5


class WiFiManager:
    def __init__(self, ssid, password):
        self.ssid = ssid
        self.password = password
        self.wlan = network.WLAN(network.STA_IF)
        self.wlan.active(True)
        
        # Reconnect state
        self.connecting = False
        self.connect_start_ms = 0
        self.last_attempt_ms = 0
        self.retry_interval_ms = WIFI_MIN_RETRY_INTERVAL_MS
        
        # Animation state
        self.anim_frame = 0
        self.last_anim_ms = 0
    
    def is_connected(self):
        return self.wlan.isconnected()
    
    def update(self):
        """Non-blocking update - wywołaj w każdej iteracji pętli głównej"""
        now = time.ticks_ms()
        
        # Jeśli połączony - reset retry interval
        if self.wlan.isconnected():
            self.connecting = False
            self.retry_interval_ms = WIFI_MIN_RETRY_INTERVAL_MS
            return "connected"
        
        # Jeśli w trakcie łączenia - sprawdź timeout
        if self.connecting:
            if time.ticks_diff(now, self.connect_start_ms) > WIFI_CONNECT_TIMEOUT_MS:
                self.connecting = False
                self.wlan.disconnect()
                # Zwiększ retry interval (exponential backoff)
                self.retry_interval_ms = min(
                    self.retry_interval_ms * 2,
                    WIFI_MAX_RETRY_INTERVAL_MS
                )
                return "timeout"
            return "connecting"
        
        # Nie połączony i nie łączy się - sprawdź czy czas na retry
        if time.ticks_diff(now, self.last_attempt_ms) >= self.retry_interval_ms:
            self._start_connect()
            return "connecting"
        
        return "waiting"
    
    def _start_connect(self):
        """Rozpocznij próbę połączenia (non-blocking)"""
        self.connecting = True
        self.connect_start_ms = time.ticks_ms()
        self.last_attempt_ms = self.connect_start_ms
        self.wlan.connect(self.ssid, self.password)
    
    def get_wifi_char(self):
        """Zwraca numer slotu custom znaku do wyświetlenia"""
        if self.wlan.isconnected():
            return SLOT_WIFI_OK
        elif self.connecting:
            # Animacja: przełączaj klatki co 250ms
            now = time.ticks_ms()
            if time.ticks_diff(now, self.last_anim_ms) > 250:
                self.anim_frame = (self.anim_frame + 1) % 4
                self.last_anim_ms = now
            return self.anim_frame  # sloty 0-3
        else:
            return SLOT_WIFI_WAIT
    
    def get_status_text(self):
        """Tekst statusu (6 znaków z paddingiem)"""
        if self.wlan.isconnected():
            return " on   "
        elif self.connecting:
            return "      "  # puste - sama ikona animowana
        else:
            secs = self.retry_interval_ms // 1000
            return " {:d}s   ".format(secs)


class Clock:
    def __init__(self):
        self.synced = False
        self.last_sync_ms = 0
    
    def sync_ntp(self):
        """Synchronizuj czas z NTP. Wywołuj tylko gdy jest połączenie WiFi."""
        try:
            ntptime.host = NTP_HOST
            ntptime.settime()
            self.synced = True
            self.last_sync_ms = time.ticks_ms()
            return True
        except:
            return False
    
    def needs_sync(self):
        """Czy potrzebna resynchronizacja (co godzinę)"""
        if not self.synced:
            return True
        return time.ticks_diff(time.ticks_ms(), self.last_sync_ms) > NTP_SYNC_INTERVAL_MS
    
    def _is_dst(self, year, month, day, weekday):
        """
        Czas letni w Polsce: ostatnia niedziela marca 02:00 → ostatnia niedziela października 03:00
        weekday: 0=poniedziałek, 6=niedziela
        """
        if month < 3 or month > 10:
            return False
        if month > 3 and month < 10:
            return True
        
        # Znajdź ostatnią niedzielę miesiąca
        # Ostatni dzień marca = 31, października = 31
        last_day = 31
        # Oblicz dzień tygodnia ostatniego dnia miesiąca
        # Różnica dni od obecnego dnia do ostatniego
        days_to_end = last_day - day
        last_day_weekday = (weekday + days_to_end) % 7
        # Ostatnia niedziela
        last_sunday = last_day - ((last_day_weekday + 1) % 7)
        
        if month == 3:
            # Po ostatniej niedzieli marca = czas letni
            return day > last_sunday or (day == last_sunday and weekday == 6)
        else:  # październik
            # Przed ostatnią niedzielą października = jeszcze czas letni
            return day < last_sunday or (day == last_sunday and weekday != 6)
    
    def get_time_str(self):
        """Zwraca czas w formacie HH:MM:SS lub --:--:-- jeśli nie zsynchronizowany"""
        if not self.synced:
            return "--:--:--"
        
        t = time.localtime()
        year, month, day, hour, minute, second, weekday, _ = t
        
        # Wybierz offset na podstawie DST
        if self._is_dst(year, month, day, weekday):
            offset = TIMEZONE_OFFSET_SUMMER
        else:
            offset = TIMEZONE_OFFSET_WINTER
        
        hour = (hour + offset) % 24
        return "{:02d}:{:02d}:{:02d}".format(hour, minute, second)


def send_ntfy(title, message, priority, tags):
    """Wyślij powiadomienie ntfy (JSON, więc polskie znaki są OK). Zwraca True, gdy serwer je przyjął."""
    payload = {
        "topic": NTFY_TOPIC,
        "title": title,
        "message": message,
        "priority": priority,
        "tags": tags,
    }
    headers = {"Content-Type": "application/json"}
    if NTFY_TOKEN:
        headers["Authorization"] = "Bearer " + NTFY_TOKEN
    r = None
    try:
        # Bajty, nie str: urequests liczy Content-Length z len(), więc polskie znaki obcięłyby treść (HTTP 400).
        body = ujson.dumps(payload).encode()
        r = requests.post(NTFY_SERVER, data=body, headers=headers, timeout=NTFY_TIMEOUT_S)
        if 200 <= r.status_code < 300:
            return True
        print("ntfy HTTP", r.status_code)
        return False
    except Exception as e:
        print("ntfy error:", e)
        return False
    finally:
        # Niezamknięta odpowiedź zostawia otwarte gniazdo TLS i po kilku alarmach kończy się pamięć.
        if r:
            r.close()
        gc.collect()


class AlarmNotifier:
    """Powiadomienia ntfy: start alarmu od razu, przypomnienia co ALERT_REPEAT_MS, a po ustaniu "Alarm ustąpił"."""

    def __init__(self):
        self.notified = None       # (co_alarm, gaz_alarm) z ostatniego powiadomienia; None = brak alarmu
        self.last_sent_ms = 0
        self.last_attempt_ms = None
        self.quiet_since_ms = None

    def _retry_wait(self, now):
        return self.last_attempt_ms is not None and time.ticks_diff(now, self.last_attempt_ms) < ALERT_RETRY_MS

    def _send(self, now, title, message, priority, tags):
        self.last_attempt_ms = now
        ok = send_ntfy(title, message, priority, tags)
        if ok:
            self.last_attempt_ms = None
        return ok

    def update(self, co_alarm, gaz_alarm, co_per, gaz_per):
        now = time.ticks_ms()
        values = "CO: {}%, Gaz: {}%".format(int(co_per), int(gaz_per))
        if co_alarm or gaz_alarm:
            self.quiet_since_ms = None
            state = (co_alarm, gaz_alarm)
            changed = state != self.notified
            due = changed or time.ticks_diff(now, self.last_sent_ms) >= ALERT_REPEAT_MS
            if not due or self._retry_wait(now):
                return
            if co_alarm and gaz_alarm:
                title = "Alarm CO + gaz"
            elif co_alarm:
                title = "Alarm CO"
            else:
                title = "Alarm gazu"
            if self._send(now, title, values, 5, ["rotating_light"]):
                self.notified = state
                self.last_sent_ms = now
        elif self.notified is not None:
            if self.quiet_since_ms is None:
                self.quiet_since_ms = now
            if time.ticks_diff(now, self.quiet_since_ms) < ALERT_CLEAR_MS or self._retry_wait(now):
                return
            if self._send(now, "Alarm ustąpił", values, 3, ["white_check_mark"]):
                self.notified = None
                self.quiet_since_ms = None


class UdpReceiver:
    """Odbiera dane jakości powietrza (broadcast UDP z Xiao ESP32S3)
    Format: {"type":"air_quality_data","devices":[{name,active,pm1_0,pm2_5,pm10,temperature,humidity,pressure}]}"""

    def __init__(self, port=UDP_AIR_PORT):
        self.port = port
        self.devices = []
        self.last_rx_ms = 0
        self.sock = None
        self._setup()

    def _setup(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.sock.bind(("0.0.0.0", self.port))
            self.sock.setblocking(False)
        except:
            self.sock = None

    def update(self):
        if self.sock is None:
            return
        try:
            raw, addr = self.sock.recvfrom(2048)
            parsed = ujson.loads(raw)
            if parsed.get("type") == "air_quality_data" and "devices" in parsed:
                self.devices = [
                    d for d in parsed["devices"] if d.get("active", False)
                ]
                self.last_rx_ms = time.ticks_ms()
        except OSError:
            pass
        except ValueError:
            pass

    def has_data(self):
        if not self.devices:
            return False
        return time.ticks_diff(time.ticks_ms(), self.last_rx_ms) < AIR_DATA_STALE_MS

    def device_count(self):
        return len(self.devices)

    def get_device(self, index):
        if 0 <= index < len(self.devices):
            return self.devices[index]
        return None


class UdpBroadcaster:
    """Nadaje dane CO/Gaz broadcastem UDP"""

    def __init__(self, port=UDP_CO2_PORT):
        self.port = port
        self.last_tx_ms = 0
        self.sock = None
        self._setup()

    def _setup(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        except:
            self.sock = None

    def send(self, co_per, gaz_per, co_digital, gaz_digital):
        if self.sock is None:
            return
        now = time.ticks_ms()
        if time.ticks_diff(now, self.last_tx_ms) < UDP_BROADCAST_INTERVAL_MS:
            return
        self.last_tx_ms = now
        try:
            payload = ujson.dumps({
                "co": round(co_per, 1),
                "gaz": round(gaz_per, 1),
                "co_digital": co_digital,
                "gaz_digital": gaz_digital
            })
            self.sock.sendto(payload, (UDP_BROADCAST_IP, self.port))
        except:
            pass


# Hardware setup
co_data = Pin(22, Pin.IN)
gaz_data = Pin(21, Pin.IN)
buzzer = Pin(20, Pin.OUT)
#ina219 = ina219.INA219(addr=0x43)

i2c = machine.I2C(1)
devices = i2c.scan()
if devices:
    for device in devices:
        print(hex(device))

def batteryRead(ina219):
    bus_voltage = ina219.getBusVoltage_V()             # voltage on V- (load side)
    current = ina219.getCurrent_mA()                   # current in mA
    P = (bus_voltage - 3) / 1.2 * 100
    if P < 0:
        P = 0
    elif P > 100:
        P = 100
    return int(P)

# LCD setup
lcd = lcd_2004.lcd(i2c, 0x3f)
lcd.lcd_backlight(True)
lcd.lcd_clear()

# Register custom characters (WiFi only)
lcd.lcd_create_char(SLOT_WIFI_1, CHAR_WIFI_1)
lcd.lcd_create_char(SLOT_WIFI_2, CHAR_WIFI_2)
lcd.lcd_create_char(SLOT_WIFI_3, CHAR_WIFI_3)
lcd.lcd_create_char(SLOT_WIFI_4, CHAR_WIFI_4)
lcd.lcd_create_char(SLOT_WIFI_OK, CHAR_WIFI_OK)
lcd.lcd_create_char(SLOT_WIFI_WAIT, CHAR_WIFI_WAIT)

lcd.lcd_print("Gas Monitor", 1, 0)

# Analog inputs
co_analog = ADC(Pin(26))
gaz_analog = ADC(Pin(27))

# Buzzer beep on startup
buzzer.value(0)
time.sleep(1)
buzzer.value(1)

# BLE setup
ble = bluetooth.BLE()
p = BLESimplePeripheral(ble, name="co")

def on_rx(v):
    print("RX", v)

p.on_write(on_rx)

# WiFi, Clock and Alert setup
wifi = WiFiManager(WIFI_SSID, WIFI_PASSWORD)
clock = Clock()
alarm_notifier = AlarmNotifier()
receiver = UdpReceiver()
broadcaster = UdpBroadcaster()


def read_sensor_avg(adc, samples=5):
    """Odczytaj średnią z kilku próbek dla stabilniejszego odczytu"""
    total = 0
    for _ in range(samples):
        total += adc.read_u16()
        time.sleep_ms(10)
    return (total / samples / 65535) * 100


# Sensor warmup with countdown
lcd.lcd_print("Gas Monitor", 1, 0)
lcd.lcd_print("Sensor warmup...", 3, 0)
for i in range(30, 0, -1):
    # Update WiFi status during warmup
    wifi.update()
    lcd.lcd_print(" WiFi:", 2, 7)
    lcd.lcd_print_char(wifi.get_wifi_char(), 2, 13)
    lcd.lcd_print(wifi.get_status_text(), 2, 14)
    
    lcd.lcd_print("Starting in {:2d}s  ".format(i), 4, 0)
    time.sleep(1)

# Try NTP sync if connected after warmup
if wifi.is_connected() and clock.needs_sync():
    clock.sync_ntp()

lcd.lcd_clear()

# Screen switching state
screen_last_switch_ms = 0
screen_interval_ms = 8000
show_air_screen = False
air_dev_index = 0
air_dev_switch_ms = 0
air_dev_interval_ms = 4000

# Main loop
while True:
    # Read sensors (averaged for stability)
    co_per = read_sensor_avg(co_analog)
    gaz_per = read_sensor_avg(gaz_analog)

    # UDP receive (non-blocking poll)
    receiver.update()

    # Screen switch timer
    now = time.ticks_ms()
    if time.ticks_diff(now, screen_last_switch_ms) >= screen_interval_ms:
        screen_last_switch_ms = now
        if receiver.has_data():
            show_air_screen = not show_air_screen
        else:
            show_air_screen = False

    # LCD rendering
    if show_air_screen:
        dev_count = receiver.device_count()
        if dev_count > 1:
            if time.ticks_diff(now, air_dev_switch_ms) >= air_dev_interval_ms:
                air_dev_switch_ms = now
                air_dev_index = (air_dev_index + 1) % dev_count
        else:
            air_dev_index = 0

        dev = receiver.get_device(air_dev_index)
        if dev:
            name = dev.get("name", "?")[:8].upper()
            pm25 = int(dev.get("pm2_5", 0))
            pm10 = int(dev.get("pm10", 0))
            temp = int(dev.get("temperature", 0))
            hum = int(dev.get("humidity", 0))
            pres = int(dev.get("pressure", 0))
            lcd.lcd_print(">{:<19s}".format(name), 1, 0)
            lcd.lcd_print("PM2.5:{:>3}  PM10:{:>3} ".format(pm25, pm10), 2, 0)
            lcd.lcd_print("Temp:{:>3}C  Hum:{:>3}% ".format(temp, hum), 3, 0)
            lcd.lcd_print("Press:{:>5}hPa      ".format(pres), 4, 0)
    else:
        # LCD line 1: title + clock (20 chars total)
        lcd.lcd_print("Gas Monitor " + clock.get_time_str(), 1, 0)

        # LCD line 2: BLE text + WiFi icon + status
        if p.is_connected():
            lcd.lcd_print("BLE:on ", 2, 0)
        else:
            lcd.lcd_print("BLE:-- ", 2, 0)
        lcd.lcd_print(" WiFi:", 2, 7)
        lcd.lcd_print_char(wifi.get_wifi_char(), 2, 13)
        lcd.lcd_print(wifi.get_status_text(), 2, 14)

        # LCD lines 3-4: sensor readings
        lcd.lcd_print("{:<20s}".format("Co: " + str(int(co_per)) + "% " + ("ok   " if co_data.value() else "alarm")), 3, 0)
        lcd.lcd_print("{:<20s}".format("Gaz: " + str(int(gaz_per)) + "% " + ("ok   " if gaz_data.value() else "alarm")), 4, 0)

    # Buzzer control
    time.sleep_ms(500)
    buzzer.value(co_data.value() and gaz_data.value())
    time.sleep_ms(500)
    buzzer.value(1)

    # BLE data send
    data = bytes([int(co_per), int(gaz_per), co_data.value(), gaz_data.value()])
    p.update(data)

    # UDP broadcast CO/Gaz data (throttled internally)
    if wifi.is_connected():
        broadcaster.send(co_per, gaz_per, co_data.value(), gaz_data.value())

    # WiFi update (non-blocking)
    wifi.update()

    # NTP sync when connected and needed
    if wifi.is_connected() and clock.needs_sync():
        clock.sync_ntp()

    # ntfy alerts
    if wifi.is_connected():
        alarm_notifier.update(not co_data.value(), not gaz_data.value(), co_per, gaz_per)
