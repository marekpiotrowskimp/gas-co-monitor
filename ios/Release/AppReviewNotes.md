# App Review Notes (EN – paste into App Store Connect)

This app displays readings from a custom Bluetooth LE carbon monoxide and gas sensor (Nordic UART service, characteristic 6E400003-B5A3-F393-E0A9-E50E24DCCA9E, manufacturer data prefix 0x69 0x69 0x02). Without the sensor the app shows "Searching for sensor…".

A video showing the app working with the sensor on iPhone and Apple Watch is attached: <LINK DO FILMU>

Capabilities:
- bluetooth-central background mode: keeps receiving sensor notifications so an alarm can be shown when CO or gas reaches a dangerous level while the app is in the background.
- Time Sensitive notifications: used only when the sensor reports a dangerous level (alarm).
- App Group: shares the latest reading between the Apple Watch app and its complications.

The app does not collect or transmit any data. The app description states that it is not a certified safety device and does not replace a standards-compliant CO / gas alarm.

---

## Do zrobienia przed wysłaniem (PL)
- Nagrać film (30–60 s): iPhone + zegarek, połączenie z czujnikiem, wzrost poziomu, alarm, komplikacja na tarczy. Wgrać (np. YouTube niepubliczny) i wstawić link.
- Zalecane: dodać tryb demo dostępny w Release (np. przytrzymanie tytułu lub przycisk „Demo” na ekranie wyboru czujnika), żeby recenzent mógł zobaczyć interfejs bez sprzętu. Obecnie tryb demo (`-mockReading`, `-mockAlarm`) działa tylko w Debug.
