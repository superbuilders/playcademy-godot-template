# Playcademy Godot SDK Sample Project

This project demonstrates how to integrate the Playcademy SDK into a Godot game.

It provides examples for:

- Initializing the SDK.
- Checking SDK readiness.
- Fetching user information.
- Interacting with the player inventory (get, add, spend items).
- Handling asynchronous operations using Godot signals.

## Prerequisites

- Godot Engine (version 4.2 or later recommended).
- The Playcademy Godot Bundle (this sample expects it to be in `addons/playcademy/`).

## Setup Instructions

1.  **Clone or Download this Sample Project.**

2.  **Install the Playcademy Godot Bundle:**

    - Ensure the `playcademy` addon directory (containing `sdk/`, `manifest_exporter/`, `shell.html` etc.) is placed into the `addons/` folder of this sample project (`templates/godot-template/addons/`).
    - You can download this bundle from the Godot AssetLib by searching for "Playcademy".

3.  **Open the Project in Godot:**

    - Open the Godot editor.
    - Click "Import" and navigate to the root folder of this sample project

4.  **Verify Plugin and Autoload:**

    - Go to `Project > Project Settings > Plugins` and ensure "Playcademy Manifest Exporter" is enabled (if you plan to use it for export; not strictly required for running this specific sample's SDK features).
    - Go to `Project > Project Settings > AutoLoad`. You should see `PlaycademySdk` listed with the path `*res://addons/playcademy/sdk/PlaycademySdk.gd`. This is configured in `project.godot`.

5.  **Review the Main Scene:**

    - The main scene is `res://scenes/Main.tscn`. It is provided as part of this template.
    - It consists of a root `Control` node with the `res://scripts/Main.gd` script attached.
    - The `Main.gd` script programmatically creates all the necessary UI child elements (Labels, Buttons) when the scene starts.
    - You do not need to manually create or modify the `Main.tscn` node structure for this sample to work, unless you wish to experiment.

## Running the Sample

- Once the setup is complete and the `Main.tscn` is correctly built, you can run the project from the Godot editor (usually by pressing F5 or the "Play" button).
- The sample UI will allow you to interact with the Playcademy SDK features.
- **Important for Web Builds**: If you export this project for the Web (HTML5), ensure your export preset uses the custom HTML shell: `res://addons/playcademy/shell.html`.

## How it Works

- **`PlaycademySDK.gd` (Autoload):** This is the main entry point for the SDK, initialized automatically.
- **`scripts/Main.gd`:** This script controls the UI and demonstrates how to:
    - Connect to SDK initialization signals (`sdk_ready`, `sdk_initialization_failed`).
    - Call methods on `PlaycademySDK.users` and `PlaycademySDK.inventory`.
    - Handle responses and errors using signals provided by the respective APIs (e.g., `get_me_succeeded`, `add_succeeded`, `add_failed`).
- **Labels and Buttons:** The UI elements display SDK status, user data, inventory contents, and results from API calls.

## Exploring the Code

- **`project.godot`**: Check the `[autoload]` section for SDK setup.
- **`scripts/Main.gd`**: This is the primary file to study for SDK usage examples.
    - Pay attention to the `_ready()` function for signal connections.
    - Look at the button press handler functions (e.g., `_on_get_user_button_pressed()`).
    - Examine the signal callback functions (e.g., `_on_get_me_succeeded()`, `_on_add_item_succeeded()`).
- **`addons/playcademy/sdk/`**: You can explore the SDK scripts themselves to understand their structure (e.g., `PlaycademySDK.gd`, `apis/users_api.gd`, `apis/inventory_api.gd`).

This sample provides a basic framework. In a real game, you would integrate these SDK calls into your game logic (e.g., granting an item when a player completes a quest).
