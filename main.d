import std.stdio;
import std.random : uniform;

static immutable string Disk = "E";
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

import Dgame.Window.all;
import Dgame.Graphics.all;
import Dgame.System.all;

import Spaceshooter.DList;

enum float Slide = 0.8f;
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

void smooth_move(Spritesheet sp, ref Vector2f slide) {
	if (slide.x != 0) {
		if (slide.x < 0f)
			inc_var(slide.x);
		else
			dec_var(slide.x);
	}

	if (slide.y != 0) {
		if (slide.y < 0f)
			inc_var(slide.y);
		else
			dec_var(slide.y);
	}

	const Vector2f pos = sp.getPosition() + slide;

	if ((pos.x + sp.width) > WinWidth || pos.x < 0)
		slide.x = 0f;
	if ((pos.y + sp.height) > WinHeight || pos.y < 0)
		slide.y = 0f;

	sp.move(slide);
}

enum State : ubyte {
	Menu,
	Game,
	Paused,
	Exit
}

void main() {
	Window wnd = new Window(VideoMode(WinWidth, WinHeight), "Spaceshooter");
	wnd.setVerticalSync(Window.Sync.Disable);
	wnd.setFramerateLimit(30);

	Image shooter_img = new Image("../../images/starship_sprite.png");
	Image bullet_img = new Image("../../images/playerBullet.png");
	Image target_img = new Image("../../images/shoot_target.png");
	Image explosion_img = new Image("../../images/explosion2.png");
	Image cloud_img = new Image("../../images/cloud.png");

	Sprite[4] clouds;
	ushort cloud_x = 0;
	foreach (ref Sprite cloud; clouds) {
		cloud = new Sprite(cloud_img);
		cloud.setPosition(cloud_x, uniform(cloud_img.height + 64, WinHeight / 2));

		cloud_x += cloud_img.width + 32;
	}

	Spritesheet shooter = new Spritesheet(shooter_img, ShortRect(0, 0, 64, 64));
	shooter.setPosition(150, 50);
	shooter.setTickOffset(80);

	DList!(Sprite) bullets;
	DList!(Spritesheet) targets;
	DList!(Spritesheet) explosions;

	Vector2f slide;
	size_t lastShot = 0;
	size_t lastEnemySpawn = 0;
	size_t escaped = 0;
	State state = State.Menu;

	Blend blend = new Blend(Blend.Mode.Multiply);

	Text text = new Text(Font("../../images/ariali.ttf", 26));
	text.setBlend(blend);

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
						case Keyboard.Code.Escape:
							EventHandler.push(Event.Type.Quit);
							break;
						case Keyboard.Code.Left:
							slide.x = -Move;
							break;
						case Keyboard.Code.Right:
							slide.x = Move;
							break;
						case Keyboard.Code.Up:
							slide.y = -Move;
							break;
						case Keyboard.Code.Down:
							slide.y = Move;
							break;
						case Keyboard.Code.Space:
							if (lastShot == 0 ||
							    (lastShot + ShotWait) < Clock.getTicks())
							{
								lastShot = Clock.getTicks();

								shooter.row = 1;

								Sprite bullet = new Sprite(bullet_img);
								bullet.setPosition(shooter.position.x + shooter.width / 3,
								                      shooter.position.y + shooter.height / 3);
								bullets.push_back(bullet);
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

		foreach (Sprite cloud; clouds) {
			cloud.move(uniform(0.5, 2.2), uniform(-1.5, 1.5));
			wnd.draw(cloud);

			if (cloud.position.x >= WinWidth)
				cloud.position.x = 0;
			if (cloud.position.y <= cloud_img.height)
				cloud.position.y = cloud_img.height;
		}

		for (auto eit = explosions.begin(); eit !is null;) {
			if (!eit.execute())
				eit = explosions.erase(eit);
			else {
				wnd.draw(eit.value);
				eit = eit.next;
			}
		}

		wnd.draw(shooter);
		smooth_move(shooter, slide);
		shooter.slideTextureRect(Spritesheet.Grid.Row);

		for (auto tit = targets.begin(); tit !is null;) {
			wnd.draw(tit.value);

			tit.move(-2, uniform(-8, 8));
			tit.slideTextureRect();

			if (tit.position.x <= 0 || tit.position.y <= 0) {
				tit.setPosition(WinWidth - 64, WinHeight / uniform(1.5, 4.5));

				escaped++;
			}

			for (auto bit = bullets.begin(); bit !is null && tit !is null;) {
				if (tit.collideWith(bit.value)) {
					Spritesheet explo = new Spritesheet(explosion_img, ShortRect(0, 0, 64, 64));
					explo.setLoopCount(1);
					explo.setTickOffset(75);
					explo.setPosition(tit.position);

					explosions.push_back(explo);

					bit = bullets.erase(bit);
					tit = targets.erase(tit);
				} else {
					bit = bit.next;
				}
			}

			if (tit is null)
				break;
			tit = tit.next;
		}
		
		for (auto bit = bullets.begin(); bit !is null;) {
			wnd.draw(bit.value);
			bit.move(Move, 0);

			if (bit.position.x > WinWidth) {
				bit = bullets.erase(bit);
			} else {
				bit = bit.next;
			}
		}

		if ((lastEnemySpawn == 0 || (lastEnemySpawn + 2000) < Clock.getTicks())) {
			Spritesheet target = new Spritesheet(target_img, ShortRect(0, 0, 64, 64));
			target.setPosition(WinWidth - 64, WinHeight / uniform(2, 4));
			targets.push_back(target);
			target.setTickOffset(60);
			
//			writefln("Spawn enemy on %f:%f", target.position.x, target.position.y);
			
			lastEnemySpawn = Clock.getTicks();
		}

		Time time = Time.remain(Clock.getTime());
		text.format("Escaped: %d        Time: %0.f min. %0.1f sec.", escaped, time.minutes, time.seconds);
		wnd.draw(text);

		wnd.display();
	}
}