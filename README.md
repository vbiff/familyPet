# FamilyPet 🐾

A beautiful Flutter app that brings families together through virtual pet care and task management. Built with modern Material Design 3 principles and clean architecture.

## 📱 Features

### 🏠 **Beautiful Home Screen**
- Personalized greetings based on time of day
- Quick stats dashboard showing tasks, pet health, and family activity
- Modern Material Design 3 interface with gradient app bar
- Smooth animations and transitions

### 📋 **Task Management**
- Create and assign tasks to family members
- Point-based reward system
- Task status tracking (Pending, In Progress, Completed)
- Beautiful card-based task list with status indicators

### 🐕 **Virtual Pet Care**
- Interactive virtual pet with health, happiness, energy, and experience stats
- Pet care actions: Feed, Play, Medical Care
- Visual progress indicators for pet stats
- Engaging pet avatar with gradient design

### 👨‍👩‍👧‍👦 **Family Management**
- Family member profiles with roles (Parent/Child)
- Online status indicators
- Member statistics (tasks completed, points earned)
- Invite new family members
- Family overview with total stats

### 🔐 **Authentication**
- Secure user authentication with Supabase
- Role-based access (Parent/Child)
- Beautiful auth forms with validation
- Automatic navigation based on auth state

## 🛠 Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Backend**: Supabase (Authentication, Database, Real-time)
- **Design**: Material Design 3
- **Architecture**: Clean Architecture with feature-first approach
- **Database**: PostgreSQL (via Supabase)

## 🏗 Architecture

The app follows Clean Architecture principles with a feature-first approach:

```
lib/
├── core/                   # Core functionality
│   ├── config/            # App configuration
│   ├── theme/             # Material Design 3 theme
│   ├── errors/            # Error handling
│   └── providers/         # Core providers (Supabase)
├── features/              # Feature modules
│   ├── auth/              # Authentication
│   │   ├── data/          # Data sources & repositories
│   │   ├── domain/        # Entities & use cases
│   │   └── presentation/  # UI & state management
│   ├── home/              # Home screen
│   ├── task/              # Task management
│   ├── pet/               # Virtual pet
│   └── family/            # Family management
└── shared/                # Shared components
```

### Architecture Principles

1. **Dependency Injection**: Dependencies flow inward only (presentation → domain → data)
2. **Pure Domain Layer**: No Flutter or infrastructure dependencies
3. **Separation of Concerns**: Each layer has a single responsibility
4. **Testability**: Clean interfaces make testing straightforward

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.0 or later)
- Dart SDK (3.0.0 or later)
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/vbiff/familyPet.git
   cd familyPet
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Copy your project URL and anon key
   - Create a `.env` file in the root directory:
     ```env
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. **Set up the database**
   - Run the SQL scripts in `supabase/schema.sql` in your Supabase SQL editor
   - This will create the necessary tables and RLS policies

5. **Run the app**
   ```bash
   flutter run
   ```

## 🗄 Database Schema

The app uses PostgreSQL with the following main tables:

- **profiles**: User profiles with roles and family associations
- **families**: Family groups
- **tasks**: Task management with assignments and rewards
- **pets**: Virtual pet data and stats

### Key Features

- **Row Level Security (RLS)**: Secure data access based on user authentication
- **Real-time subscriptions**: Live updates for family activities
- **Enum types**: Task status, user roles, task frequency
- **Cascade deletions**: Proper data cleanup

## 🎨 Design System

### Material Design 3

The app implements Material Design 3 with:

- **Dynamic Color**: Adaptive color schemes
- **Surface containers**: Proper elevation and layering
- **Typography scale**: Consistent text hierarchy
- **Component tokens**: Modern button styles and navigation

### Key Design Principles

- **Clean and minimal**: Focus on content and functionality
- **Family-friendly**: Engaging colors and animations
- **Accessible**: Proper contrast ratios and touch targets
- **Responsive**: Adapts to different screen sizes

## 🧪 Testing

Run tests with:

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests (if available)
flutter test integration_test/
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🔒 Security

- **Authentication**: Secure user authentication via Supabase Auth
- **Authorization**: Role-based access control
- **Data Protection**: Row Level Security (RLS) in database
- **API Security**: Secure API calls with proper authentication headers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the established architecture patterns
- Write tests for new features
- Use conventional commits
- Ensure code passes `flutter analyze`
- Follow Flutter best practices

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) for the amazing framework
- [Supabase](https://supabase.com) for the backend infrastructure
- [Material Design 3](https://m3.material.io) for design guidance
- [Riverpod](https://riverpod.dev) for state management

## 📞 Support

If you have any questions or issues, please:

1. Check the [Issues](https://github.com/vbiff/familyPet/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide detailed information about your environment and the issue

---

**Made with ❤️ for families everywhere**
