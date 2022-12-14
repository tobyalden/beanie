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
    private var isDead:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        id = 0;
        hitbox = new Hitbox(20, 20);
        mask = hitbox;
        sprite = new Spritemap("graphics/player.png", 20, 20);
        sprite.add("idle", [0]);
        graphic = sprite;
        isDead = false;
    }

    override public function update() {
        //trace('player: rider: ${rider}. riding: ${riding}');
        if(isDead) {
            super.update();
            return;
        }

        var buddy = collide("buddy", x, y);
        if(
            buddy != null
            && velocity.y > 0
            && centerY < buddy.centerY
        ) {
            if(riding == null) {
                riding = cast(buddy, Controllable);
                riding.setRider(this);
            }
        }
        if(riding == null) {
            movement();
        }
        else if (riding.riding == null) {
            if(Input.check("up") && Input.pressed("jump") && !Controllable.dismountedThisFrame) {
                dismount();
            }
        }

        animation();

        if(collide("hazard", x, y) != null) {
            die();
        }
        super.update();
    }

    private function die() {
        visible = false;
        collidable = false;
        isDead = true;
        explode(50);
        detachAllRiding();
        //sfx["die"].play();
        // TODO: stop sfx
        cast(HXP.scene, GameScene).onDeath();
    }

    private function animation() {
    }
}
