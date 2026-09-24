# Spec for the Gomoku UI

## Handoff

The UI should listen to the core game logic signals. When a player places a piece, the core game logic should emit an event with the board coordinate and the piece color. When the game starts and ends it should also emit a signal. The core game logic should offer functions to change the game state, such as placing a piece as a player, conceding, etc. that user inputs from the UI can trigger to interact with the game logic.

## Directory
The UI flutter files will live in _csc4330_app_4/lib/ui/*.dart