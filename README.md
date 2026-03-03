# Campus Online

A professional mobile application that provides information about services within the university, such as working hours, menus, and locations. Built with a modern tech stack to ensure high performance, security, and a beautiful user experience.

---

## Features

- **User Authentication**: Secure login, registration, and profile management powered by Supabase Auth.
- **Venue Information**: View comprehensive details about various venues on campus, including working hours, location details, and descriptions.
- **Search & Filtering**: Quickly search for venues by name, location, or discover venues via categories.
- **Favorites & Recent Views**: Save favorite venues for quick access and track your recently viewed places.
- **Administrator Panel**: Integrated admin dashboard to add, edit, or delete venue data on the fly.
- **Modern UI**: Clean, intuitive user interface featuring smooth animations, glassmorphism, and responsive layouts.

## Tech Stack

- **Frontend Toolkit**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Backend as a Service (BaaS)**: [Supabase](https://supabase.com/) (PostgreSQL Database & Authentication)

---

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- A Supabase account and project
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/campus_online.git
   ```

2. Navigate to the project directory:
   ```bash
   cd campus_online
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Supabase:
   - Create a new Supabase project.
   - Set up the required tables: `users`, `venues`, `user_favorites`, `user_recent_views`, and `user_recent_searches`.
   - Ensure Row Level Security (RLS) policies are correctly configured.
   - Update the initialization code in `lib/main.dart` with your unique `url` and `anonKey`.

5. Run the app:
   ```bash
   flutter run
   ```

---

## Project Structure

- `lib/models`: Data models representing database entities
- `lib/screens`: UI screens and page layouts
- `lib/services`: Supabase interactions and generic services
- `lib/widgets`: Modular and reusable UI components
- `lib/providers`: State management nodes defined with Riverpod
- `lib/theme` / `lib/utils`: Theming rules, constants, and helper functions

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
