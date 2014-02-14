module Spaceshooter.Game;

import std.random : uniform;

public {
	import Dgame.Window.all;
	import Dgame.Graphics.all;
	import Dgame.System.all;
}

import Spaceshooter.List;
import Spaceshooter.utils;
import Spaceshooter.constants;

enum State : ubyte {
	Menu,
	Game,
	Options
}

final class Game {
	State state;
	bool paused;

	Vector2f slide;
	size_t lastShot = 0;
	size_t lastEnemySpawn = 0;
	size_t escaped = 0;

	Image shooter_img;
	Image bullet_img;
	Image target_img;
	Image explosion_img;
	Image cloud_img;

	Spritesheet shooter;
	Sprite[4] clouds;

	DList!(Sprite) bullets;
	DList!(Spritesheet) targets;
	DList!(Spritesheet) explosions;

	Text text;

	this() {
		this.shooter_img = new Image("../../images/starship_sprite.png");
		this.bullet_img = new Image("../../images/playerBullet.png");
		this.target_img = new Image("../../images/shoot_target.png");
		this.explosion_img = new Image("../../images/explosion2.png");
		this.cloud_img = new Image("../../images/cloud.png");

		ushort cloud_x = 0;
		foreach (ref Sprite cloud; this.clouds) {
			cloud = new Sprite(cloud_img);
			cloud.setPosition(cloud_x, uniform(this.cloud_img.height + 64, WinHeight / 2));
	
			cloud_x += cloud_img.width + 32;
		}

		this.shooter = new Spritesheet(this.shooter_img, ShortRect(0, 0, 64, 64));
		this.shooter.setPosition(150, 50);
		this.shooter.setTickOffset(80);

		Blend blend = new Blend(Blend.Mode.Multiply);
	
		this.text = new Text(Font("../../font/ariali.ttf", 26));
		this.text.setBlend(blend);
		this.text.move(32, 8);
	}

	void run(Window wnd) {
		Event event;
		while (EventHandler.poll(&event)) {
			switch (event.type) {
				default: break;
				
				case Event.Type.Quit:
					wnd.close();
					break;
				
				case Event.Type.KeyDown:
					switch (event.keyboard.key) {
						case Keyboard.Code.Escape:
							this.state = State.Menu;
							break;
						case Keyboard.Code.Pause:
							this.state = State.Menu;
							this.paused = true;
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
							if (this.paused)
								break;

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
			}
		}

		if (escaped >= MaxEscape) {
			text("You lose");
			text.setPosition(WinWidth / 2, WinHeight / 2 - text.height);
		} else {
			if (this.paused)
				return;

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
				
				writefln("Spawn enemy on %f:%f", target.position.x, target.position.y);
				
				lastEnemySpawn = Clock.getTicks();
			}

			Time time = Time.remain(Clock.getTime());
			text.format("Escaped: %d / %d        Time: %0.f min. %0.1f sec.",
			            escaped, MaxEscape, time.minutes, time.seconds);
		}

		wnd.draw(text);
	}
}