# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WasurenBou (わすれん棒) is an iOS/watchOS reminder app specifically designed for forgetful people. The app emphasizes a kind, non-judgmental UX with escalating notifications to ensure reminders are not missed.

**Core Concept**: "忘れることは悪いことじゃない。思い出すお手伝いをするだけです。" (Forgetting isn't bad. We're just here to help you remember.)

## Build and Development Commands

### Building the Project
```bash
# Build for simulator (recommended device: iPhone 16 Pro for screenshots)
xcodebuild -project WasurenBou.xcodeproj -scheme WasurenBou -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' build

# Build for device (requires signing configuration)
xcodebuild -project WasurenBou.xcodeproj -scheme WasurenBou -configuration Release -destination 'generic/platform=iOS' build

# Clean build
xcodebuild -project WasurenBou.xcodeproj -scheme WasurenBou clean
```

### Version Management
```bash
# Update build number (current: 1.0(7))
agvtool new-version [BUILD_NUMBER]

# Check current version
agvtool what-version
agvtool what-marketing-version
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project WasurenBou.xcodeproj -scheme WasurenBou -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Run specific test
xcodebuild test -project WasurenBou.xcodeproj -scheme WasurenBou -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' -only-testing:WasurenBouTests/SpecificTestClass/testMethod
```

### Simulator Management
```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot [DEVICE_ID]

# Install app to simulator
xcrun simctl install [DEVICE_ID] /path/to/WasurenBou.app

# Launch app
xcrun simctl launch [DEVICE_ID] com.lizaria.WasurenBou
```

## Architecture Overview

### MVVM + Combine Architecture
The app follows MVVM pattern with Combine for reactive data binding:

- **Models**: Core Data entities (`Reminder`, `ReminderTemplate`) with auto-generated classes
- **ViewModels**: `ReminderViewModel` manages business logic and Core Data operations
- **Views**: SwiftUI views (`ContentView`, `TimeSelectionView`, etc.)
- **Services**: Isolated service layers for specific functionalities

### Service Layer Architecture
Services are singleton instances managing specific domains:

1. **NotificationService** (`@MainActor`): Manages all notification logic including:
   - Escalating notification system (initial → reminder → urgent → critical)
   - Notification actions (complete/snooze from notification)
   - UNUserNotificationCenterDelegate implementation

2. **SpeechRecognitionService** (`@MainActor`): Handles voice input:
   - Japanese language recognition (`ja-JP` locale)
   - Real-time transcription with partial results
   - Intelligent text processing and correction

3. **PersistenceController**: Core Data stack management:
   - iCloud sync capability (CloudKit)
   - Preview context for SwiftUI previews
   - Background context support

### Data Flow
```
User Input (Voice/UI) → ViewModel → Service Layer → Core Data/Notifications
                          ↑                               ↓
                      SwiftUI Views ← Published Properties
```

### Notification Escalation System
The app implements a unique 4-level escalation for forgetful users:
1. **Initial** (0 min): Standard notification
2. **Reminder** (5 min): Gentle reminder
3. **Urgent** (10 min): Stronger alert with ringtone
4. **Critical** (15 min): Critical alert with maximum prominence

Each reminder schedules all 4 notifications, with later ones cancelled upon completion.

### Voice Recognition Integration
Voice input flow:
1. `VoiceInputButton` manages recording state
2. `SpeechRecognitionService` handles Speech Framework integration
3. `processTranscription()` applies intelligent corrections for common phrases
4. `ReminderViewModel.processVoiceInput()` creates templates from recognized patterns

### Core Data Model Structure
**Entities**:
- **Reminder**: Basic reminders with escalating notifications
  - `title`, `scheduledTime`, `isCompleted`, `notificationIdentifiers`
- **ReminderTemplate**: Frequently used reminder patterns
  - `title`, `emoji`, `usageCount`, `lastUsed`
- **Checklist**: Group of items with location/reminder capabilities
  - `title`, `emoji`, `reminderEnabled`, `isLocationBased`, `latitude/longitude`
- **ChecklistItem**: Individual checklist items
  - `title`, `isChecked`, `order`

**Relationships**: Checklist → ChecklistItem (one-to-many, cascade delete)

## Critical Implementation Details

### Actor Isolation
- Services using notifications or UI updates are marked with `@MainActor`
- Delegate methods use `nonisolated` with `Task { @MainActor }` for UI updates
- This prevents Swift concurrency warnings while maintaining thread safety

### Core Data Auto-Generation
- DO NOT manually create `Reminder+CoreDataClass.swift` or `ReminderTemplate+CoreDataClass.swift`
- Core Data auto-generates these files during build
- Use extension files for custom methods: `Reminder+Extensions.swift`, `ReminderTemplate+Extensions.swift`

### Privacy Permissions
The app requires these Info.plist keys (added to project build settings):
- `INFOPLIST_KEY_NSMicrophoneUsageDescription`: Microphone access for voice input
- `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription`: Speech recognition permission

### Build Configuration
- **App Name**: Remind!!! (code name: WasurenBou)
- **Minimum iOS**: 18.2 (configured in project settings)
- **Swift Version**: 5.0
- **Development Team**: RVU4KGDM65
- **Bundle ID**: com.lizaria.WasurenBou
- **Current Version**: 1.0 (7)

### AdMob Configuration
- **App ID**: ca-app-pub-4187811193514537~8449937639
- **Banner Unit ID**: ca-app-pub-4187811193514537/6354257330
- **Test Ads**: Automatically used in Debug builds
- **Production Ads**: Used in Release builds only

## Common Development Tasks

### Adding New Reminder Features
1. Update Core Data model in `WasurenBou.xcdatamodeld`
2. Clean build to regenerate Core Data classes
3. Add business logic to `ReminderViewModel`
4. Update UI in relevant SwiftUI views

### Modifying Notification Behavior
1. Edit `NotificationService.scheduleEscalatingNotifications()`
2. Adjust escalation levels in `NotificationLevel` enum
3. Test with different time intervals in simulator

### Enhancing Voice Recognition
1. Add correction patterns in `SpeechRecognitionService.processTranscription()`
2. Update template matching in `ReminderViewModel.findAndUseMatchingTemplate()`
3. Test with Japanese voice input in simulator/device

### Template Display Issues
If templates show empty icons/titles:
1. Check `ReminderViewModel.findAndUseMatchingTemplate()` is public (not private)
2. Ensure template usage tracking calls `incrementUsage()` and saves context
3. Verify cache is cleared after template updates: `cache.removeObject(forKey: "templates")`

## Project Structure Notes

- **Extensions/**: Core Data entity extensions for custom methods
- **Services/**: Singleton services (AdMob, Location, Speech, Notifications, etc.)
- **ViewModels/**: MVVM view models managing business logic
- **Views/**: SwiftUI views for different features
- **Resources/**: Localization files (ja.lproj, en.lproj, Base.lproj)
- **ViewModifiers/**: Custom SwiftUI modifiers (DesignSystem, AnimationSystem)
- **Models/**: Swift model classes (Checklist, ChecklistItem)
- **build/**: Auto-generated build artifacts (ignore in development)

## Localization Architecture

### Language Support
- **Primary**: Japanese (`ja_JP`) - Default development language
- **Secondary**: English (`en_US`) - International support
- **Fallback**: English for missing Japanese localizations

### Localization Files Structure
```
Resources/
├── Base.lproj/          # English base localization
├── ja.lproj/           # Japanese localization  
└── en.lproj/           # English localization
```

### Key Implementation Details
- App determines locale in `WasurenBouApp.determineAppLocale()`
- All user-facing strings use `NSLocalizedString()`
- Speech recognition defaults to `ja-JP` locale
- Bundle localization configuration in Info.plist

## Testing Considerations

- Voice recognition requires device/simulator with microphone support
- Notifications require proper entitlements and user permission
- Core Data operations should be tested with both empty and populated stores
- Test escalating notifications with accelerated time intervals for development
- AdMob ads automatically use test IDs in Debug builds, production IDs in Release builds
- Location-based features require physical device for accurate GPS testing
- Premium features (in-app purchase) testing requires App Store Connect configuration

## App Store Preparation

### Current Status
- **Version**: 1.0 (7) - Ready for submission
- **Localization**: Complete (Japanese/English)
- **AdMob Integration**: Configured and ready
- **Privacy**: ATT and GDPR compliance implemented
- **Support Site**: https://s-maemura.github.io/WasurenBou-support/

### Required Screenshots
- iPhone 6.7" (1284×2778px): Use iPhone 16 Pro simulator
- Screenshots stored in: `/Users/s.maemura/AppPJ/sc/`

### Key App Store Metadata
- **Bundle ID**: com.lizaria.WasurenBou
- **App Name**: Remind!!!
- **Category**: Productivity  
- **Age Rating**: 4+
- **In-App Purchase**: Premium features ¥480