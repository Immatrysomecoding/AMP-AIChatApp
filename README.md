# AMP-AIChatApp

A Flutter application for AI chatting with a clean, modern interface.

## Mock UI

This branch contains the mock UI implementation for the application. We've created interface designs for the login, signup, chat, bot management, and chat history screens with overlay functionality.

### Widget Tree

Widget tree screeonshots:

in screenshot folder

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
        └── Stack
            ├── Column (Main Content)
            │   ├── Expanded (Chat messages)
            │   │   └── SingleChildScrollView
            │   │       └── Column
            │   │           ├── Center (Welcome message)
            │   │           ├── Container (Pro version)
            │   │           ├── Row (Prompts section)
            │   │           └── Container (Prompt buttons)
            │   ├── Container (Message input area)
            │   │   └── Row
            │   │       ├── Model selector
            │   │       ├── Create bot button
            │   │       ├── Action icons
            │   │       └── Input field wrapper
            │   └── Container (Token counter)
            └── PromptLibraryOverlay (Slides in from right)
                └── Column
                    ├── Header (Title and close button)
                    ├── Tabs (Public/My Prompts)
                    ├── Search field
                    ├── Categories
                    └── Prompt items list
```

#### Bot Screen:

```
Scaffold
└── Row
    ├── Sidebar (with BOT selected)
    │   └── Column
    │       ├── Container (Logo)
    │       ├── InkWell (Chat option)
    │       ├── InkWell (BOT option - selected)
    │       ├── InkWell (Group option)
    │       ├── Spacer
    │       └── Container (Bottom icons)
    └── Expanded (Bot List)
        └── Stack
            ├── Column (Main Content)
            │   ├── Text (Title - "Bots")
            │   ├── TextField (Search)
            │   ├── Row
            │   │   ├── DropdownButton (Filter)
            │   │   └── ElevatedButton (Create Bot)
            │   └── Expanded (ListView)
            │       └── BotCard (Bot items)
            │           ├── Row (Bot header)
            │           │   ├── Icon
            │           │   ├── Text (Bot name)
            │           │   └── Action buttons
            │           ├── Text (Description)
            │           └── ElevatedButton (Chat Now)
            └── CreateBotDialog (When visible)
                └── Column
                    ├── Header (Title and close button)
                    ├── TextField (Name)
                    ├── TextField (Instructions)
                    ├── Knowledge base section
                    └── Action buttons (Cancel, Create)
```

#### Chat History Screen:

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
    └── Expanded (Chat History List)
        └── Column
            ├── Row (Header)
            │   ├── Icon
            │   ├── Text ("Your chat history")
            │   └── Cancel button (when in selection mode)
            ├── TextField (Search)
            ├── Row (Selection info)
            │   ├── Text (Count of chats)
            │   └── Select button (or selection count when active)
            └── Expanded (ListView)
                └── ChatHistoryCard (for each chat)
                    ├── Selection indicator (when in selection mode)
                    ├── Text (Chat title)
                    └── Text (Last message timestamp)
```

![Widget Tree Diagram]([https://drive.google.com/file/d/17GKlDe2Oq3MVcfSEGbvkOPy_cN1ZSjCd/view?usp=sharing](https://drive.google.com/file/d/17GKlDe2Oq3MVcfSEGbvkOPy_cN1ZSjCd/view?usp=sharing))

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
- Bot Screen: `/bot`
- Chat History Screen: `/history`

## Overlay Features

The app includes overlay panels and dialogs:

- **Prompt Library**: Slides in from the right side when "View all" is clicked
  - Shows a list of available prompts
  - Includes tabs for Public/My Prompts
  - Provides category filtering
  - Each prompt has star, info, and use buttons

- **Create Prompt Dialog**: Center modal dialog when the "+" button is clicked in Prompt Library
  - Form with fields for prompt name and content
  - Explanatory information about prompt syntax
  - Cancel and Create buttons for form submission

- **Create Bot Dialog**: Center modal dialog when the "Create Bot" button is clicked in Bot Screen
  - Form with fields for bot name and instructions
  - Knowledge base section with option to add sources
  - Cancel and Create buttons for form submission

## Project Structure

```
lib/
├── main.dart                  # App entry point and routes
├── screens/                   # App screens
│   ├── login_screen.dart      # Login screen
│   ├── signup_screen.dart     # Signup screen
│   ├── chat_screen.dart       # Chat main screen
│   ├── bot_screen.dart        # Bot management screen
│   └── chat_history_screen.dart # Chat history screen
└── widgets/                   # Reusable widgets
    ├── sidebar.dart           # App sidebar navigation
    ├── chat_area.dart         # Chat area content
    ├── prompt_library_overlay.dart  # Prompt library slide-in panel
    ├── create_prompt_dialog.dart    # Create prompt modal dialog
    ├── bot_list.dart          # Bot list content
    ├── bot_card.dart          # Individual bot card
    ├── create_bot_dialog.dart # Create bot modal dialog
    ├── chat_history_list.dart # Chat history list
    └── chat_history_card.dart # Individual chat history item
```

## Features Implemented

1. **Authentication Screens**
   - Login screen with email/password and Google sign-in options
   - Signup screen with form validation
   - "Welcome to Jarvis" introduction panel

2. **Chat Interface**
   - Main chat area with welcome message and prompt suggestions
   - Message input with model selection and formatting options
   - Token counter and upgrade prompt

3. **Bot Management**
   - Bot listing with search and filtering
   - Bot creation dialog with name, instructions, and knowledge base
   - Bot interaction options (share, favorite, chat)

4. **Chat History**
   - Searchable list of previous conversations
   - Selection mode for batch operations
   - Chat cards with title and last message timestamp

5. **Navigation & Layout**
   - Sidebar for main app navigation
   - Consistent theming across all screens
   - Responsive layout that works on various screen sizes

## Next Steps

After implementing this mock-UI, the project can proceed to:
1. Implement actual authentication functionality
2. Connect to a backend for chat and bot management
3. Implement real prompt functionality
4. Add state management for a production application
