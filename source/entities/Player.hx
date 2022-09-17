package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Player extends Controllable
{
    private var sprite:Spritemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        id = 0;
        hitbox = new Hitbox(20, 20);
        mask = hitbox;
        sprite = new Spritemap("graphics/player.png", 20, 20);
        sprite.add("idle", [0]);
        graphic = sprite;
    }

    override public function update() {
        //trace('player: rider: ${rider}. riding: ${riding}');

        var buddy = collide("buddy", x, y);
        if(buddy != null) {
            if(riding == null) {
                riding = cast(buddy, Controllable);
                riding.setRider(this);
            }
        }
        if(riding == null) {
            movement();
        }
        animation();
        super.update();
    }

    private function animation() {
    }
}
