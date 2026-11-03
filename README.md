# gas-co-monitor

Monitor czujnika gazu / CO: urządzenie na **Raspberry Pi Pico W** + aplikacja **iOS / watchOS** z widgetami.

| Katalog | Zawartość |
|---|---|
| [`raspberry-pi/`](raspberry-pi/) | MicroPython: odczyt czujnika, wyświetlacz LCD 20×4, BLE, powiadomienia push przez [ntfy](https://ntfy.sh) |
| [`ios/`](ios/) | Aplikacja GazCoMonitor (SwiftUI, BLE), widget iOS, aplikacja i widget Apple Watch, pakiet `GasCoKit` |

## Raspberry Pi Pico W

```sh
cp raspberry-pi/config.example.py raspberry-pi/config.py   # Wi-Fi + temat/token ntfy, plik w .gitignore
```

Wgraj pliki z `raspberry-pi/` na Pico (np. `mpremote cp *.py :`).

## iOS

Projekt generowany przez [XcodeGen](https://github.com/yonaskolb/XcodeGen): `cd ios && xcodegen && open GazCoMonitor.xcodeproj`.
Materiały do wydania w App Store: [ios/Release/](ios/Release/).
