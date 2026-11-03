# Release 2.0 – GazCoMonitor

This directory contains everything needed to release version 2.0 on the App Store.

| File | Contents |
|---|---|
| [AppStoreAudit.md](AppStoreAudit.md) | What version 1.0 looks like on the App Store today and what needs fixing (in Polish) |
| [metadata/pl.md](metadata/pl.md) | Name, subtitle, description, keywords, "What's New" – Polish |
| [metadata/en.md](metadata/en.md) | The same – English |
| [AppReviewNotes.md](AppReviewNotes.md) | Notes for the Apple reviewer (BLE hardware, background mode, notifications) |
| [PrivacyPolicy.md](PrivacyPolicy.md) | Privacy policy text to publish at a public URL |
| [screenshots/](screenshots/) | Simulator screenshots: iPhone 6.9" (1320×2868) and Apple Watch Ultra (422×514), PL/EN |

## Version
- Marketing: **2.0**, build **5** (`project.yml`)
- iOS 18.0+, watchOS 11.0+ (currently in the store: iOS 17.4+)
- The watch app runs independently (`WKRunsIndependentlyOfCompanionApp`)

## Pre-submission checklist

### Code / build
- [x] PL/EN localization (app, watch, widget, name under the icon, Bluetooth usage description)
- [x] `ITSAppUsesNonExemptEncryption = NO` (no encryption question)
- [x] Signing with the paid team `JMMW48F6X4`, App Group, Time Sensitive
- [ ] New app icon (see audit, item 6) – iPhone + watch
- [ ] Demo mode in the Release build for the reviewer (see AppReviewNotes) – recommended
- [ ] Test with a real sensor: connection, reconnection, alarm, complication after 15 min
- [ ] Archive → Validate → Upload (scheme `GazCoMonitor`, Release configuration)

### App Store Connect
- [ ] Add the **Polish** localization (currently English only)
- [ ] Fill in the metadata from `metadata/pl.md` and `metadata/en.md`
- [ ] Replace the iPhone screenshots and **add Apple Watch screenshots**
- [ ] Publish the privacy policy and replace the URL (currently LinkedIn)
- [ ] Support URL
- [ ] Secondary category: change "Developer Tools" → "Lifestyle" (or remove it)
- [ ] Accessibility: declare VoiceOver, Dark Interface, Larger Text
- [ ] App Review Information: paste the notes, attach a video of the app working with the sensor
- [ ] App privacy: "Data Not Collected" stays true (data is local only)
