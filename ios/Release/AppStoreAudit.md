# Audyt App Store – stan na 3.10.2026

Strona: https://apps.apple.com/pl/app/gazcomonitor/id6720758613

## Co jest w sklepie

| Pole | Wartość dziś |
|---|---|
| Nazwa | GazCoMonitor |
| Wersja | 1.0 – wydana 15.10.2024, od tamtej pory bez aktualizacji |
| Opis | Jedno zdanie: „Hazard Monitoring - monitorowanie poziomu tlenku węgla i gazu.” |
| Języki | English (choć interfejs i opis są po polsku) |
| Kategorie | Utilities, Developer Tools |
| Wymagania | iOS 17.4+, iPhone + Apple Watch |
| Rozmiar | 1,2 MB |
| Oceny | brak |
| Polityka prywatności | profil LinkedIn |
| Prywatność | Data Not Collected |
| Accessibility | niezadeklarowane |
| Zrzuty | 4 × iPhone, 0 × Apple Watch |

## Problemy i poprawki

### Krytyczne (ryzyko odrzucenia / wprowadzania w błąd)
1. **Polityka prywatności = LinkedIn.** Wytyczna 5.1.1 wymaga dostępnej polityki prywatności. Opublikować `PrivacyPolicy.md` (np. GitHub Pages / Notion) i podmienić URL.
2. **Brak zastrzeżenia bezpieczeństwa.** Aplikacja dotyczy zagrożenia życia (CO, gaz). Wytyczna 1.4.1: opis musi jasno mówić, że wymaga zewnętrznego czujnika i **nie zastępuje certyfikowanej czujki CO/gazu**. Dodane w nowych metadanych.
3. **Recenzent nie ma czujnika.** Bez sprzętu aplikacja pokazuje tylko „Szukanie czujnika…”. Dołączyć film z działania i opis (AppReviewNotes.md); zalecany tryb demo w Release.

### Zrzuty ekranu
4. Obecne zrzuty to surowe screeny z telefonu:
   - widać „◀ TestFlight” w pasku statusu,
   - na 1. zrzucie powiadomienie z innej aplikacji (ikona terminala, „gaz Alarm”),
   - wartość **101%** – wygląda jak błąd,
   - stary interfejs (wersja 1.0), godziny 18:06–18:09 zamiast 9:41.
   - **Brak zrzutów Apple Watch**, choć aplikacja jest na zegarek.
   → Nowe zrzuty w `screenshots/` (status bar 9:41, PL i EN). Zalecane dodać napisy marketingowe nad zrzutami (np. „Alarm natychmiast na nadgarstku”).

### Metadane
5. Opis ma jedno zdanie; brak podtytułu, słów kluczowych, tekstu promocyjnego → `metadata/`.
6. **Ikona:** symbol promieniowania (☢) sugeruje radioaktywność, nie CO/gaz; napisy „HAZARD MONITORING / CO AND GAS” są nieczytelne w małych rozmiarach (ekran główny, zegarek). Propozycja: płomień + chmurka CO na ciemnym tle, kolory z aplikacji (zielony/żółty/czerwony), bez tekstu.
7. Nazwa „GazCoMonitor” miesza PL i EN. Propozycja nazwy w sklepie (lokalizowana):
   - PL: **Gaz / CO Monitor**
   - EN: **Gas & CO Monitor**
   Bundle ID bez zmian. Nazwa pod ikoną po aktualizacji: „Gaz / CO” / „Gas / CO”.
8. Język sklepu: tylko English, a treść po polsku → dodać lokalizację Polski, EN przetłumaczyć.
9. Kategoria „Developer Tools” nie pasuje → „Lifestyle” jako dodatkowa (główna: Utilities).
10. Accessibility nie zadeklarowane → wersja 2.0 wspiera VoiceOver (opisy wskaźników), Dark Interface, Larger Text, Differentiate Without Color (ikony + tekst obok kolorów).

### Techniczne (naprawione w wersji 2.0)
- Aplikacja łączyła się z pierwszym czujnikiem w zasięgu, nie z zapamiętanym.
- Brak ponownego łączenia po utracie zasięgu.
- Brak obsługi wyłączonego Bluetooth / braku zgody.
- Opis uprawnienia Bluetooth tylko po angielsku.
- Brak komplikacji na tarczę, historii, powiadomień, wyboru czujnika.
- Minimalny iOS podniesiony do 18.0 – **użytkownicy na iOS 17 zostaną na wersji 1.0** (świadoma decyzja).
