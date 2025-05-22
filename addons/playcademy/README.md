# Playcademy Godot Bundle

This directory contains Playcademy assets for Godot Engine, designed to streamline the integration of your Godot games with the Playcademy platform.

The asset bundle includes the following key components:

## 1. Manifest Exporter Plugin (`manifest_exporter/`)

This is a Godot editor plugin that helps you prepare your game for the Playcademy platform. Its primary functions include:

- **Game Metadata Definition**: Allows you to define and export essential metadata about your game, such as its name, version, entry scene, and other platform-specific configurations.
- **Asset Packaging**: Assists in organizing and declaring the assets your game uses, ensuring they are correctly recognized and handled by the Playcademy system.
- **Simplified Export**: Streamlines the process of exporting your game in a format compatible with Playcademy.

To use the Manifest Exporter, simply enable it in your Godot project's `Project > Project Settings > Plugins` tab after downloading this asset via AssetLib (or else manually placing this directory into your project's `addons/` directory).

## 2. Playcademy SDK & Web Shell

This section covers the Playcademy Software Development Kit (SDK) and the HTML shell required for web-based deployments.

### Playcademy SDK (`sdk/`)

The SDK provides the necessary tools and libraries to connect your Godot game with Playcademy's backend services. This enables features such as:

- User authentication and management.
- Player inventory interactions.
- Runtime behaviour (e.g. exit game)

Refer to the [SDK documentation](https://docs.playcademy.net/platform-guides/godot.html) for details on how to integrate these features into your game logic.

### Required HTML Shell (`shell.html`) for Web Exports

When deploying your game to the Playcademy web platform, the SDK relies critically on the provided `shell.html`. This HTML file is not just a template but a **vital component** specifically configured to:

- Ensure seamless operation and proper initialization of your game within the Playcademy web environment.
- Handle the embedding of the Godot game canvas correctly.
- Facilitate essential communication channels between your Godot game, the SDK, and the Playcademy platform.

**Using a custom HTML shell without incorporating the necessary Playcademy hooks may lead to SDK features not functioning as expected, or a complete failure of integration on the web platform.**

## 3. Installation

1.  Download and copy (manually or via AssetLib) the entire `playcademy` directory into the `addons/` folder of your Godot project.
2.  Enable the "Playcademy Manifest Exporter" plugin via `Project > Project Settings > Plugins` in the Godot editor.
3.  The "Playcademy SDK" scripts within the `sdk/` folder will be directly accessible for you to use in your game scenes. Ensure your web export settings utilize the provided `shell.html` if deploying to the Playcademy platform.
