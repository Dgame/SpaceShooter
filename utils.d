module Spaceshooter.utils;

import Dgame.Graphics.Spritesheet;
import Dgame.Math.Vector2;

import Spaceshooter.constants;

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