# Release 2.0 – GazCoMonitor

Katalog zawiera wszystko, co jest potrzebne do wydania wersji 2.0 w App Store.

| Plik | Zawartość |
|---|---|
| [AppStoreAudit.md](AppStoreAudit.md) | Jak dziś wygląda wersja 1.0 w App Store i co trzeba poprawić |
| [metadata/pl.md](metadata/pl.md) | Nazwa, podtytuł, opis, słowa kluczowe, „Co nowego” – PL |
| [metadata/en.md](metadata/en.md) | To samo – EN |
| [AppReviewNotes.md](AppReviewNotes.md) | Notatki dla recenzenta Apple (sprzęt BLE, tło, powiadomienia) |
| [PrivacyPolicy.md](PrivacyPolicy.md) | Treść polityki prywatności do opublikowania pod publicznym URL |
| [screenshots/](screenshots/) | Zrzuty z symulatora: iPhone 6.9" (1320×2868) i Apple Watch Ultra (422×514), PL/EN |

## Wersja
- Marketing: **2.0**, build **5** (`project.yml`)
- iOS 18.0+, watchOS 11.0+ (w sklepie dziś: iOS 17.4+)
- Aplikacja na zegarek działa samodzielnie (`WKRunsIndependentlyOfCompanionApp`)

## Checklist przed wysłaniem

### Kod / build
- [x] Lokalizacja PL/EN (aplikacja, zegarek, widget, nazwa pod ikoną, opis Bluetooth)
- [x] `ITSAppUsesNonExemptEncryption = NO` (brak pytania o szyfrowanie)
- [x] Podpisywanie zespołem płatnym `JMMW48F6X4`, App Group, Time Sensitive
- [ ] Nowa ikona aplikacji (patrz audyt, pkt 6) – iPhone + zegarek
- [ ] Tryb demo w buildzie Release dla recenzenta (patrz AppReviewNotes) – zalecane
- [ ] Test na prawdziwym czujniku: połączenie, ponowne łączenie, alarm, komplikacja po 15 min
- [ ] Archive → Validate → Upload (schemat `GazCoMonitor`, konfiguracja Release)

### App Store Connect
- [ ] Dodać lokalizację **Polski** (dziś tylko English)
- [ ] Uzupełnić metadane z `metadata/pl.md` i `metadata/en.md`
- [ ] Podmienić zrzuty ekranu iPhone i **dodać zrzuty Apple Watch**
- [ ] Opublikować politykę prywatności i podmienić URL (dziś LinkedIn)
- [ ] Support URL
- [ ] Kategoria dodatkowa: zmienić „Developer Tools” → „Lifestyle” (lub usunąć)
- [ ] Accessibility: zadeklarować VoiceOver, Dark Interface, Larger Text
- [ ] App Review Information: wkleić notatki, dołączyć film z działania z czujnikiem
- [ ] Prywatność aplikacji: „Data Not Collected” pozostaje prawdziwe (dane tylko lokalnie)
