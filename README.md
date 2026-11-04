# Sprout

## Overview

**Sprout** is an iOS app for keeping track of plants and their care routines. It uses local weather forecasts to help adjust scheduled tasks, so watering reminders can take changing conditions into account.

The app is built with SwiftUI and follows the MVVM architecture. It also uses Supabase for its backend, PlantNet for plant identification, and the OpenAI API to generate 3D plant models.

## Installation

Choose one of the following methods to install Sprout on your iOS device.

| Method | Download |
|:---|:---|
| **AltStore Classic** | [Install with AltStore](https://intradeus.github.io/http-protocol-redirector?r=altstore-classic://install?url=https://github.com/Vidunixel/Sprout/releases/download/v1.0.0/Sprout.ipa) |
| **SideStore** | [Install with SideStore](https://intradeus.github.io/http-protocol-redirector?r=sidestore://install?url=https://github.com/Vidunixel/Sprout/releases/download/v1.0.0/Sprout.ipa) |
| **LiveContainer** | [Install with LiveContainer](https://intradeus.github.io/http-protocol-redirector?r=livecontainer://install?url=https://github.com/Vidunixel/Sprout/releases/download/v1.0.0/Sprout.ipa) |
| **Direct Download** | [Download IPA](https://github.com/Vidunixel/Sprout/releases/download/v1.0.0/Sprout.ipa) |

## Key Features

- **Weather-based care reminders:** Checks the local forecast against care thresholds and adjusts relevant plant tasks when conditions are expected to change.
- **3D plant models:** Generates plant models as OpenSCAD code and displays them in the app.
- **Plant identification:** Uses the PlantNet API to identify plants from photos and help fill in their details.
- **Care history:** Keeps a cloud-synced record of completed plant care tasks.
- **iOS features:** Uses SwiftUI, supports light and dark mode, and schedules local notifications.

## Pictures

| <img width="400" alt="Plant Details Light Mode" src="https://github.com/user-attachments/assets/6127c066-397d-41d7-9284-e4f76528b0aa" /> | <img width="400" alt="Plant Details Dark Mode" src="https://github.com/user-attachments/assets/cf1dd24f-4967-459f-b19a-b6f50d09ae07" /> |
|:--:|:--:|
| *Plant details in light mode.* | *Plant details in dark mode.* |

| <img width="400" alt="Creating Garden" src="https://github.com/user-attachments/assets/eef4c47f-e796-47bb-8436-94256f94450a" /> | <img width="400" alt="Garden" src="https://github.com/user-attachments/assets/d783ea74-bbb0-4dff-b6ed-d4c1a340169c" /> |
|:--:|:--:|
| *Creating a garden.* | *Garden.* |

| <img width="400" alt="Adding Plant" src="https://github.com/user-attachments/assets/f940996b-11a0-4e2a-9ea3-ede5d201d77d" /> | <img width="400" alt="Account Page" src="https://github.com/user-attachments/assets/86fdf3b9-b46e-4a18-9967-59b84229794d" /> |
|:--:|:--:|
| *Adding a plant.* | *Account page.* |

| <img width="400" alt="Tasks" src="https://github.com/user-attachments/assets/37f2a91c-8482-45ee-9f42-8a6757f78386" /> | <img width="400" alt="Task Details" src="https://github.com/user-attachments/assets/11bc4557-27f9-4e99-a625-d4a717d0a2ac" /> |
|:--:|:--:|
| *Tasks page.* | *Task details.* |

## Technical Implementation

### Weather-based task adjustments and notifications

Weather-related scheduling is handled mainly by `WeatherEvaluationService` and `WeatherAdjustmentStore`.

1. **Get the forecast:** `OpenMetroService` retrieves a 7-day forecast from the Open-Meteo REST API. The app uses the `LocalityAutocomplete` wrapper to resolve the user's location to coordinates.
2. **Check the conditions:** `WeatherEvaluationService` compares the forecast with the care thresholds stored in the user's `Plant` models. For example, if the chance of rain is above 70% and the temperature is below a set threshold, an outdoor watering task may need to be moved.
3. **Update the task:** `WeatherAdjustmentStore` changes the task date and creates a `WeatherAdjustmentTimeline` record. This keeps a record of when a task was moved and why.
4. **Update notifications:** `NotificationService` uses Apple's `UNUserNotificationCenter` to manage local notifications. When a task changes, it finds and cancels the existing notification using the task's unique identifier, then schedules a replacement with the updated details. The notification can include a reason for the change, such as: "Watering delayed until Thursday due to forecasted heavy rain".

### Plant identification

Sprout uses the PlantNet API to identify plants from photos.

1. The user takes a photo using `CameraPicker`, a SwiftUI wrapper around `UIImagePickerController`.
2. The app compresses the image and sends it to PlantNet in a multipart form-data request through `PlantNetService`.
3. The response is parsed into `PlantNetResult` and `PlantAnalysisResult` data objects. These contain information such as the plant's taxonomy, common names and confidence scores.
4. `AddPlantViewModel` uses the results to fill in the plant details and looks up default care schedules for the identified species.

### 3D plant model generation

Sprout generates plant models when needed instead of relying on a collection of pre-made 3D assets.

1. **Create the prompt:** `OpenAiService` sends a prompt to the OpenAI API with details about the identified plant.
2. **Generate the model code:** The API returns OpenSCAD code describing the plant.
3. **Render the model:** The app sends the code to a custom rendering service hosted on Vercel: https://github.com/Vidunixel/sprout-functions.
4. **Display the model:** The rendering service runs OpenSCAD and converts the code into a 3D mesh. The app receives the result and displays it using `PlantScene`, a wrapper that uses SceneKit.

## Architecture and Tech Stack

Sprout uses the **MVVM (Model-View-ViewModel)** pattern to keep the user interface separate from the app's data and business logic.

**Core technologies**

- **Language:** Swift 5.0+
- **UI framework:** SwiftUI
- **State management:** `@StateObject`, `@EnvironmentObject` and custom stores such as `TaskStore` and `GardenStore`.
- **Asynchronous tasks:** Swift Concurrency (`async/await`) for API and database requests.

**Backend and infrastructure**

- **Supabase:** Handles the app's backend services.
  - **PostgreSQL:** Stores users, gardens, plants and task logs.
  - **Supabase Auth:** Manages user authentication and sessions.
  - **Supabase Edge Functions:** Runs TypeScript functions that handle requests to external APIs.
- **Vercel:** Hosts the Node.js service used to compile OpenSCAD files.

**External APIs**

- **OpenAI API:** Generates OpenSCAD code for plant models.
- **Open-Meteo API:** Provides weather forecasts.
- **PlantNet API:** Identifies plants from images.

## Project Structure

```text
p9-custom-app/
├── Models/             # Data models (Plant, Task, WeatherAdjustment, etc.)
├── Views/              # SwiftUI views grouped by feature
├── ViewModels/         # View models and related app logic
├── Services/           # API clients and core services (OpenAi, Weather, PlantNet)
├── Stores/             # Shared state (GardenStore, TaskStore)
├── Wrappers/           # UIKit and SceneKit wrappers (CameraPicker, PlantScene)
└── Extensions/         # Swift extensions and UI utilities
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ Simulator or device
- A Supabase project with its URL and anon key
- API keys for OpenAI and PlantNet

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/sprout-ios.git
   ```

2. Open `p9-custom-app.xcodeproj` in Xcode.

3. Add your credentials to `AppConfig.swift`:

   ```swift
   static let supabaseURL = "YOUR_SUPABASE_URL"
   static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```

4. Build and run the project using **Cmd + R** on a simulator or connected device.
