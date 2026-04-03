HollowWard – Multiplayer Horror Game (Roblox)

🎮 Overview

HollowWard is a multiplayer survival horror experience built on Roblox, where players must work together (or alone) to complete objectives and escape while being hunted by a terrifying AI-controlled monster.

This project focuses on:

🧠 Intelligent enemy AI
🎯 Objective-based gameplay
⚙️ Modular and scalable architecture
🎨 Immersive UI and player controls
🚀 Features
👹 Advanced Monster AI
Dynamic player tracking and chasing
Behavior-based decision making
Increasing difficulty over time
🎯 Objective System
Complete tasks to unlock escape routes
Centralized objective manager
Scalable for future missions
👥 Multiplayer Ready
Player state management
Server-client communication via RemoteEvents
Smooth synchronization
🎮 Player Experience
Custom player controller
Interactive UI system
Real-time feedback and game updates
🚪 Escape Mechanics
Exit door system tied to objectives
Endgame triggers and win conditions
🗂️ Project Structure
HollowWard/
│
├── ServerScriptService/
│   ├── GameManager.lua        # Core game loop & state control
│   ├── PlayerManager.lua      # Player handling & tracking
│   ├── MonsterAI.lua          # AI logic for enemy behavior
│   ├── ObjectiveManager.lua   # Objective system
│   ├── ExitDoor.lua           # Escape logic
│   └── RemoteEvents.lua       # Client-server communication
│
├── StarterPlayerScripts/
│   ├── PlayerController.lua   # Player movement & input
│   └── GameUI.lua             # UI rendering & updates
│
├── ReplicatedStorage/
│   └── GameConfig.lua         # Game configuration & constants
│
└── SETUP_GUIDE.md             # Setup instructions
⚙️ Installation & Setup
Clone or download this repository
Open your Roblox Studio project
Import scripts into their respective services:
ServerScriptService
StarterPlayerScripts
ReplicatedStorage
Follow detailed steps in SETUP_GUIDE.md
Run the game in Play mode 🎮
🧩 How It Works
GameManager controls the overall game flow (start, end, transitions)
PlayerManager tracks player states (alive, dead, escaped)
MonsterAI actively hunts players using scripted logic
ObjectiveManager assigns and validates tasks
RemoteEvents ensure smooth client-server communication
UI + Controller provide player interaction and feedback
📌 Future Improvements
🔊 Sound design & jump scares
🗺️ Multiple maps
🧍 Character progression system
🤖 Smarter AI (learning/adaptive behavior)
🎭 Different monster types
🛠️ Tech Stack
Platform: Roblox
Language: Lua
Architecture: Client-Server model
