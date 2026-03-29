# DriftMac — Launch Checklist

## Pre-Launch

### Code & Build
- [ ] All unit tests pass
- [ ] Build succeeds (Release, arm64)
- [ ] No hardcoded secrets or API keys in source
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) present
- [ ] App icon at all required sizes (16, 32, 64, 128, 256, 512, 1024)

### Entitlements
- [ ] `com.apple.developer.healthkit` entitlement enabled
- [ ] HealthKit capability added in Xcode
- [ ] App Sandbox enabled (if distributing outside Mac App Store)
- [ ] Hardened Runtime enabled (for notarization)

### App Store Connect
- [ ] App Store Connect account set up (paid developer account required)
- [ ] New app record created in App Store Connect
- [ ] Bundle ID registered: `com.drift.mac`
- [ ] Category set to **Health & Fitness**
- [ ] Content rights declared (or "Does Not Contain Third-Party Code" selected)
- [ ] Age rating questionnaire completed

### Marketing
- [ ] App Store listing written (`Marketing/APPSTORE.md`)
- [ ] Screenshots captured (dark purple theme, 1x and 2x)
- [ ] App icon ready at all sizes
- [ ] Keywords researched and entered (max 100 chars)
- [ ] Privacy policy URL ready (required for HealthKit apps)

### Code Signing
- [ ] Developer ID Application certificate created in Apple Developer portal
- [ ] Signing identity selected in Xcode (Developer ID Application)
- [ ] `CODE_SIGN_IDENTITY` set for Release
- [ ] Provisioning profile created (for Mac App Store) or notarization ready (for direct distribution)

## Submission

- [ ] Archive built in Xcode (Product → Archive)
- [ ] App validated and uploaded from Organizer
- [ ] Wait for App Store Connect processing (~15–30 min)
- [ ] **Manually submit for review** (don't rely on auto-submit)
- [ ] Review submission selected: "Health & Fitness" / No exotic content
- [ ] Notes to reviewer: "DriftMac reads sleep data from Apple HealthKit. No data leaves the device."
- [ ] Export Compliance: US Census endpoint — select "No" unless using HTTPS for all API calls

## Post-Submission

- [ ] Monitor App Store Connect for "In Review" status
- [ ] Review typically takes 24–48 hours for macOS apps
- [ ] If rejected: read rejection reason, fix, resubmit
- [ ] Once approved: manually release or set automatic release date
- [ ] Announce launch (optional: social, GitHub, etc.)

## Direct Distribution (Alternative to Mac App Store)

- [ ] Notarize app: `xcrun notarytool submit DriftMac.app`
- [ ] Sign installer (if using pkg): `productsign`
- [ ] Host download with release notes
- [ ] Provide a checksum (SHA-256) for verification
- [ ] Include uninstall instructions

---

## Quick Commands

```bash
# Build for release
xcodebuild -scheme DriftMac -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  build CODE_SIGN_IDENTITY="Developer ID Application: YOUR_NAME" 2>&1 | tail -20

# Archive
xcodebuild -scheme DriftMac -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  archive CODE_SIGN_IDENTITY="Developer ID Application: YOUR_NAME"

# Notarize (after signing)
xcrun notarytool submit DriftMac.app --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" --password "APP_PASSWORD"
```
