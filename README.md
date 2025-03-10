# BrainIncubator

A comprehensive iOS app for managing ICD-11 transition in healthcare organizations.

## Features

- Interactive training modules for ICD-11 transition
- Self, team, and organizational assessments
- Progress tracking and notifications
- Dark mode support
- Local data persistence
- Analytics tracking
- Privacy-focused design

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/BrainIncubator.git
cd BrainIncubator
```

2. Open the project in Xcode
```bash
open Package.swift
```

3. Build and run the project using Xcode

## Development Setup

### Core Data
The app uses Core Data for local persistence. The model is defined in `Sources/Core/BrainIncubator.xcdatamodeld`.

### Notifications
Local notifications are used for reminders. Configure notification permissions in device settings.

### Analytics
Analytics tracking is implemented using the system logger for development and can be extended with third-party services for production.

## Testing

Run unit tests using Xcode's test navigator or via command line:
```bash
swift test
```

## Deployment

1. Configure your Apple Developer account in Xcode
2. Update version numbers in Info.plist
3. Create an archive using Xcode
4. Submit to App Store using App Store Connect

## Privacy

- All data is stored locally on device
- No personal information is collected
- Usage analytics are anonymized
- Notifications are device-local only

## Support

For support inquiries, contact support@brainincubator.com

## License

Copyright © 2024 BrainIncubator. All rights reserved.