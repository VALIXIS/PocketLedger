# 🚀 Production Release Checklist — PocketLedger v1.0.0+1
**Date**: September 27, 2026

- [ ] **Code Audit**: Run `valixis-gatekeeper check --fast` (Verify 0 lints, 0 Hive ID conflicts).
- [ ] **Unit & Widget Tests**: All tests passing (`flutter test`).
- [ ] **Android Build**: `flutter build appbundle --release` (Generates `build/app/outputs/bundle/release/app-release.aab`).
- [ ] **iOS Build**: `flutter build ipa --release`.
- [ ] **Google Play Console**:
  - Upload `.aab` to Closed Testing / Production track.
  - Paste release notes from `release_dossier/google_play_metadata/whats_new.txt` (324/500 chars).
- [ ] **Apple App Store Connect**:
  - Distribute build via Transporter / Xcode.
  - Paste release notes from `release_dossier/apple_app_store_metadata/whats_new.txt`.
- [ ] **Git Tagging**: `git tag -a v1.0.0 -m "Release v1.0.0+1" && git push origin --tags`.
