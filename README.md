# Dialegume
An Open Source Dialog System for the Godot game engine. Dialegume is designed to make adding dialog to you game easy while still being customizeable.

It is designed to handle:

1.  Text scaling (keep the same number of lines.)
2.  Character animations (moving from left to right.)
3.  Character emotions (different images depending on emotion.)
4.  Branching decisions.
5.  Triggering in game events.
6.  Item/object pictures (icons to indicate characters interacting with an object.)
7.  Easy translating.
8.  Special text for key items or button names.
9.  Custom features via custom handlers.

## How to

1.  Copy (and optionally customize) `res://addons/dialegume/sample/dialog_box.tscn` to somewhere else in your project.
2.  Add your copied dialog box scene to your UI.
3.  Write your script in Dialegume XML.
4.  Call `load_dialog(path: str)` on the dialog box with the path to your dialog file.
5.  Call `continue_dialog()` on the dialog box when the user presses a key (such as space bar.)

### Writing Dialegume XML

TODO: Fully Document the Dialegume XML format

A sample conversation and supporting files are included in `res://addons/dialegume/sample/dialog_box.tscn` for users to see. The file `res://addons/dialegume/sample/conversations/sample-dialog.tldr-dxml` contains XML comments (look for `<!-- comment here -->`) discussing many of the available tags.

### Customizing The Dialog Box

TODO: Fully Document customization methods

There are a bunch of settings that need to be applied to the child nodes used by the dialog box. To get these correct, it is recommended to copy the `res://addons/dialegume/sample/dialog_box.tscn` scene and customize things from there.
