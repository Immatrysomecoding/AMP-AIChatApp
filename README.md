# AMP-AIChatApp

A Flutter application for AI chatting with a clean, modern interface.

## Mock UI

This branch contains the mock UI implementation for the application. We've created interface designs for the login, signup, and chat screens.

### Widget Tree

#### Login/Signup Screens:

```
Scaffold
└── SafeArea
    └── Row
        ├── Expanded (Left side)
        │   └── Container
        │       └── Column
        │           ├── Row (Logo)
        │           ├── Text (Welcome)
        │           ├── Text (Description)
        │           └── GridView (Platform icons)
        │               ├── Container (Icon 1)
        │               ├── Container (Icon 2)
        │               ├── ...
        │               └── Container (Icon 6)
        └── Container (Right side - Form)
            └── Column
                ├── Text (Title)
                ├── Row (Account status)
                ├── ElevatedButton (Google sign in/up)
                ├── Row (Or continue with)
                ├── TextField (Email)
                ├── TextField (Password)
                ├── TextField (Confirm Password - only in signup)
                ├── TextButton (Forgot password - only in login)
                └── ElevatedButton (Sign in/up)
```

#### Chat Screen:

```
Scaffold
└── Row
    ├── Sidebar
    │   └── Column
    │       ├── Container (Logo)
    │       ├── InkWell (Chat option)
    │       ├── InkWell (BOT option)
    │       ├── InkWell (Group option)
    │       ├── Spacer
    │       └── Container (Bottom icons)
    └── Expanded (Chat Area)
        └── Column
            ├── Expanded (Chat messages)
            │   └── SingleChildScrollView
            │       └── Column
            │           ├── Center (Welcome message)
            │           ├── Container (Pro version)
            │           └── Row (Prompts section)
            ├── Container (Message input area)
            │   └── Row
            │       ├── Model selector
            │       ├── Create bot button
            │       ├── Action icons
            │       └── Input field wrapper
            └── Container (Token counter)
```

![Widget Tree Diagram](https://raw.githubusercontent.com/Immatrysomecoding/AMP-AIChatApp/mock-ui/widget_tree.png)

## Setup

1. Clone the repository
2. Switch to the mock-ui branch: `git checkout mock-ui`
3. Run `flutter pub get` to install dependencies
4. Run the app: `flutter run`

## Navigation

The app uses basic navigation between screens:
- Login Screen: `/login`
- Signup Screen: `/signup`
- Chat Screen: `/chat`
