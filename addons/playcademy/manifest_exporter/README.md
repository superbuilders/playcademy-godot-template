# Playcademy Manifest Exporter (Godot Plugin)

A Godot editor plugin that automatically generates a `playcademy.manifest.json` file when exporting HTML5 projects, tailored for the Playcademy platform.

## Purpose

The Playcademy platform requires a `playcademy.manifest.json` file to correctly integrate and load HTML5 games. This plugin automates the creation of this manifest, ensuring your Godot web exports are Playcademy-ready.

## Features

- **Automatic Manifest Generation:** Creates the `playcademy.manifest.json` file in your web export directory.
- **Playcademy Ready:** Simplifies the preparation of your Godot web games for the Playcademy platform.
- **Seamless Integration:** Works automatically during the standard Godot HTML5 export process once the plugin is enabled.

## Manual Installation

1.  Download the contents of this addon (the `manifest_export` folder).
2.  Place the `manifest_export` folder into your Godot project's `addons/` directory. If you don't have an `addons/` directory, create one at the root of your project.
    Your project structure should look like:
    ```
    my_godot_project/
    ├── addons/
    │   └── playcademy/manifest_exporter/
    │       ├── plugin.gd
    │       ├── plugin.cfg
    │       ├── playcademy_exporter.gd
    └── project.godot
    ... (other project files)
    ```
3.  Enable the plugin:
    - Open your Godot project.
    - Go to `Project` -> `Project Settings...` -> `Plugins` tab.
    - Find "Playcademy Manifest Exporter" in the list and check the "Enable" box.

## How to Use

Once installed and enabled, the plugin works automatically. When you export your project for the "Web" (HTML5) platform, the `playcademy.manifest.json` file will be created in the root of your export directory alongside your game's `html`, `js`, and `pck` files.

## License

This plugin is released under the MIT License. See the [LICENSE](LICENSE) file for more details.
