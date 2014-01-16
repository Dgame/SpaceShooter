import std.stdio;

pragma(lib, "E:\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictSDL2.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictUtil.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\derelict\\lib\\dmd\\DerelictGL3.lib");

pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameInternal.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameAudio.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameGraphics.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameSystem.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameMath.lib");
pragma(lib, "E:\\D\\dmd2\\src\\ext\\Dgame\\lib\\Release\\DgameWindow.lib");

import Dgame.Window.all;
import Dgame.Graphics.all;
import Dgame.System.all;

import Spaceshooter.List;

enum float Slide = 0.6f;
enum short Move = 15;
enum ushort WinWidth = 640;
enum ushort WinHeight = 480;
enum ubyte ShotWait = 100;

void inc_var(ref float d) pure nothrow {
	if (d < 0f) {
		d += Slide;
		if (d > 0f)
			d = 0f;
	}
}

void dec_var(ref float d) pure nothrow {
	if (d > 0f) {
		d -= Slide;
		if (d < 0f)
			d = 0f;
	}
}

void smooth_move(Spritesheet sp, ref float x, ref float y) {
	if (x != 0) {
		if (x < 0f)
			inc_var(x);
		else
			dec_var(x);
	}

	if (y != 0) {
		if (y < 0f)
			inc_var(y);
		else
			dec_var(y);
	}

	const float nx = sp.X + x;
	const float ny = sp.Y + y;

	if ((nx + sp.width) > WinWidth || nx < 0)
		x = 0f;
	if ((ny + sp.height) > WinHeight || ny < 0)
		y = 0f;

	sp.move(x, y);
}

enum State : ubyte {
	Menu,
	Game,
	Paused,
	Exit
}

void main() {
	Window wnd = new Window(VideoMode(WinWidth, WinHeight), "Dgame Test");
	wnd.setVerticalSync(Window.Sync.Disable);
	wnd.setFpsLimit(30);

	Image bullet = new Image("../../images/playerBullet.png");

	Image shooter_img = new Image("../../images/starship_sprite.png");
	Spritesheet shooter = new Spritesheet(shooter_img, ShortRect(0, 0, 64, 64));
	shooter.setPosition(150, 50);

	List!Sprite bullets = new List!Sprite();

	float sx = 0f, sy = 0f;
	size_t lastShot = 0;
	State state = State.Menu;

	Event event;
	while (wnd.isOpen()) {
		wnd.clear();
		
		while (EventHandler.poll(&event)) {
			switch (event.type) {
				case Event.Type.Quit:
					writeln("Quit Event");
					
					wnd.close();
					break;

				case Event.Type.KeyDown:
					switch (event.keyboard.key) {
						case Keyboard.Code.Left:
							sx = -Move;
							break;
						case Keyboard.Code.Right:
							sx = Move;
							break;
						case Keyboard.Code.Up:
							sy = -Move;
							break;
						case Keyboard.Code.Down:
							sy = Move;
							break;
						case Keyboard.Code.Space:
							if (lastShot == 0 || (lastShot + ShotWait) < Clock.getTicks()) {
								lastShot = Clock.getTicks();

								shooter.row = 1;

								Sprite my_bullet = new Sprite(bullet);
								my_bullet.setPosition(shooter.X + shooter.width, shooter.Y + (shooter.height / 2));
								bullets.push_back(my_bullet);
							}
							break;
						default: break;
					}
					break;
				
				case Event.Type.KeyUp:
					if (event.keyboard.key == Keyboard.Code.Space)
						shooter.row = 0;
					break;

				default: break;
			}
		}

		smooth_move(shooter, sx, sy);
		shooter.slideTextureRect(Spritesheet.Grid.Row);

		size_t i = 0;
		for (auto it = bullets.top(); it !is null; it = it.next) {
			wnd.draw(it.value);

			it.value.move(Move, 0);
			if (it.value.X > WinWidth) {
				writeln("Remove it: ", it.value);
				it = bullets.erase(it);
			}
		}

		wnd.draw(shooter);

		wnd.display();
	}
}