import std.stdio;

static immutable string Disk = "D";
static immutable string Mode = "Release";

pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictSDL2.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictUtil.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictGL3.lib");

pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameInternal.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameAudio.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameGraphics.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameSystem.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameMath.lib");
pragma(lib, Disk ~ ":\\D\\dmd2\\src\\ext\\Dgame\\lib\\" ~ Mode ~ "\\DgameWindow.lib");

import Spaceshooter.Game;

Sprite[2][string] Buttons;
ubyte[string] ButtonIds;

static this() {
	ButtonIds = [
		"Exit": 0,
		"Continue": 0,
		"New Game": 0
	];
}

void showMenu(Window wnd, ref Game game) {
	Event event;
	while (EventHandler.poll(&event)) {
		switch (event.type) {
			case Event.Type.Quit:
				wnd.close();
				break;
			
			case Event.Type.KeyDown:
				if (event.keyboard.code == Keyboard.Code.Escape)
					EventHandler.push(Event.Type.Quit);
				break;

			case Event.Type.MouseMotion:
				foreach (string key, ref Sprite[2] btns; Buttons) {
					if (key == "Continue" && !game.paused)
						continue;

					if (btns[0].getClipRect().contains(event.mouseMotion.x, event.mouseMotion.y))
						ButtonIds[key] = 1;
					else
						ButtonIds[key] = 0;
				}
				break;
			
			case Event.Type.MouseButtonDown:
				foreach (string key, ref Sprite[2] btns; Buttons) {
					if (key == "Continue" && !game.paused)
						continue;
					if (key == "New Game" && game.paused)
						continue;
					
					if (btns[0].getClipRect().contains(event.mouseButton.x, event.mouseButton.y))
					{
						switch (key) {
							default: break;
							case "Exit":
								wnd.close();
								break;
							case "Continue":
								game.paused = false;
								game.state = State.Game;
								break;
							case "New Game":
								game.state = State.Game;
								break;
						}
					}
				}
				break;

			default: break;
		}
	}

	wnd.draw(Buttons["Exit"][ButtonIds["Exit"]]);
	wnd.draw(Buttons["Continue"][ButtonIds["Continue"]]);
	wnd.draw(Buttons["New Game"][ButtonIds["New Game"]]);
}

void gameLoop(Window wnd, ref Game game) {
	game.run(wnd);
}

void main() {
	import Spaceshooter.constants;

	Window wnd = new Window(VideoMode(WinWidth, WinHeight), "Spaceshooter");
	wnd.setVerticalSync(Window.Sync.Disable);
	wnd.setFramerateLimit(30);
	Surface icon = Surface("../../images/icon.png");
	wnd.setIcon(icon);

	Game game = new Game();

	Buttons = [
		"Exit" : [
			new Sprite(new Image("../../images/exit_button.png")),
			new Sprite(new Image("../../images/exit_button_blended.png"))
		],
		"Continue" : [
			new Sprite(new Image("../../images/continue_button.png")),
			new Sprite(new Image("../../images/continue_button_blended.png"))
		],
		"New Game" : [
			new Sprite(new Image("../../images/newgame_button.png")),
			new Sprite(new Image("../../images/newgame_button_blended.png"))
		],
	];

	ushort button_y = 64;
	foreach (string key, ref Sprite[2] btns; Buttons) {
		btns[0].setPosition(WinWidth / 4, button_y);
		btns[1].setPosition(WinWidth / 4, button_y);

		button_y += btns[0].height + 16;
	}

	while (wnd.isOpen()) {
		wnd.clear();

		final switch (game.state) {
			case State.Game:
				gameLoop(wnd, game);
				break;
			case State.Menu:
				showMenu(wnd, game);
				break;
			case State.Options:
				break;
		}

		wnd.display();
	}
}