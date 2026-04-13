# M-CARS Food App - Flutter Frontend

A modern, AI-powered food delivery application built with Flutter.

## 🚀 Features
- **AI Recommendations**: Smart food suggestions based on user behavior and time of day.
- **Authentication**: Secure login and sign-up powered by Supabase.
- **Modern UI**: Premium design with smooth gradients, shadow effects, and a feature-based architecture.
- **State Management**: Built with Riverpod for robust and scalable state handling.

## 📂 Project Structure
The project follows a **Feature-First Architecture**:

```text
lib/
├── core/             # Centralized themes, constants, and network logic
├── features/         # Individual app features (Auth, Home, Main Navigation)
│   ├── auth/         # Login, Registration, Password recovery
│   ├── home/         # Dashboard, AI recommendations, Restaurant list
│   └── main/         # Root navigation and bottom bar
└── shared/           # Reusable components and utility functions
    └── widgets/      # Common UI elements (Cards, Buttons, Inputs)
```

## 🛠️ Setup
1. Ensure you have [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
2. Clone the repository.
3. Run `flutter pub get` to install dependencies.
4. Update `lib/main.dart` with your **Supabase URL** and **Anon Key**.
5. Run the app using `flutter run`.

## 🎨 Design System
- **Colors**: Deep Orange, Vivid Red, and clean white backgrounds.
- **Typography**: Inter (Modern Sans Serif).
- **Aesthetics**: Glassmorphism elements, soft shadows, and vibrant gradients.
