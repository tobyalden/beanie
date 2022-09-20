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
        super.update();
    }

    override private function die() {
        super.die();
        visible = false;
        collidable = false;
        isDead = true;
        explode();
        //sfx["die"].play();
        // TODO: stop sfx
        cast(HXP.scene, GameScene).onDeath();
    }

    private function explode() {
        var numExplosions = 50;
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2 / numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(0.8 * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            var explosion = new Particle(
                centerX, centerY, directions[count], 1, 1
            );
            explosion.layer = -10;
            HXP.scene.add(explosion);
            count++;
        }

#if desktop
        Sys.sleep(0.02);
#end
        HXP.scene.camera.shake(0.5, 2);
    }

    private function animation() {
    }
}
