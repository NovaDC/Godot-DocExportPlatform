# Godot-DocExportPlatform

An EditorExportPlatform for Godot used to export api documents using godot's export menu into a wide array of document formats.

Depending on the formats desired to export to, the [sphinx](https://www.sphinx-doc.org "Sphinx homepage") document generator and/or Godot's [make_rst.py](https://github.com/godotengine/godot/blob/master/doc/tools/make_rst.py "make_rst.py as hosted on Github") script (and its dependencies) must also be available.
This plugin also provides means for easy installation of [make_rst.py](https://github.com/godotengine/godot/blob/master/doc/tools/make_rst.py "make_rst.py as hosted on Github") and [Godot's official sphinx conf](https://github.com/godotengine/godot-docs "Godot's sphinx conf as hosted on Github").

![The DocEditorExportPlatform icon](https://raw.githubusercontent.com/godotengine/godot/refs/heads/master/editor/icons/Help.svg "Icon")

The icon for this plugin is unmodified and used [directly from the Godot Editor](https://github.com/godotengine/godot/blob/master/editor/icons/Help.svg "Link to the original icon as hosted on Github") wherever possible. It is used under the Godot game engine's [MIT licence](https://github.com/godotengine/godot/blob/master/LICENSE.txt).

## Dependencies

Exporting documents beyond [Godot's xml format](https://docs.godotengine.org/en/stable/engine_details/class_reference/index.html "Official documentation describing Godot's specific xml documentation format") will require python, and exporting any format besides rst or [Godot's xml](https://docs.godotengine.org/en/stable/engine_details/class_reference/index.html "Official documentation describing Godot's specific xml documentation format") will require [sphinx](https://www.sphinx-doc.org "Sphinx homepage") to be installed in that same python environment.

Requires the [NovaTools](https://github.com/NovaDC/Godot-Novatools "NovaTools Github Repository") plugin as a dependency.
[NovaTools](https://github.com/NovaDC/Godot-Novatools "NovaTools Github Repository") does not need to be enabled for this plugin to function.
