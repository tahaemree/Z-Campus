# Campus Online

A mobile application that provides information about services within the university, such as working hours, menus, and locations.

## Features

- **User Authentication**: Login and registration with Firebase Authentication
- **Venue Information**: View details about various venues on campus
- **Search Functionality**: Search for venues by name or category
- **Favorites**: Save favorite venues for quick access
- **Modern UI**: Clean and intuitive user interface with smooth animations

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/campus_online.git
   ```

2. Navigate to the project directory:
   ```
   cd campus_online
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the `google-services.json` file to the `android/app` directory
   - Download and add the `GoogleService-Info.plist` file to the `ios/Runner` directory

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/models`: Data models for the application
- `lib/screens`: UI screens
- `lib/services`: Firebase and other services
- `lib/widgets`: Reusable UI components
- `lib/providers`: State management with Riverpod

## Firebase Setup

1. Create a new Firebase project
2. Enable Authentication with Email/Password
3. Create a Firestore database
4. Set up security rules for Firestore
5. Add sample venue data to Firestore

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
