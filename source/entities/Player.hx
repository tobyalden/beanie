package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Player extends Entity
{
    public static inline var SPEED = 175;
    public static inline var GRAVITY = 900;
    public static inline var MAX_FALL_SPEED = 300;
    public static inline var MAX_RISE_SPEED = 200;
    public static inline var JUMP_POWER = 400;
    public static inline var JUMP_CANCEL_POWER = 40;

    private var velocity:Vector2;
    private var sprite:Spritemap;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Hitbox(20, 20);
        sprite = new Spritemap("graphics/player.png", 20, 20);
        sprite.add("idle", [0]);
        graphic = sprite;
        velocity = new Vector2();
    }

    override public function update() {
        movement();
        animation();
        super.update();
    }

    private function movement() {
        if(Input.check("left")) {
            velocity.x = -SPEED;
        }
        else if(Input.check("right")) {
            velocity.x = SPEED;
        }
        else {
            velocity.x = 0;
        }

        if(isOnGround()) {
            velocity.y = 0;
            if(Input.pressed("jump")) {
                velocity.y = -JUMP_POWER;
            }
        }
        else {
            var gravity:Float = GRAVITY;
            if(Math.abs(velocity.y) < JUMP_CANCEL_POWER) {
                gravity *= 0.5;
            }
            if(Input.released("jump") && velocity.y < -JUMP_CANCEL_POWER) {
                velocity.y = -JUMP_CANCEL_POWER;
            }
            velocity.y += gravity * HXP.elapsed;
            velocity.y = Math.min(velocity.y, MAX_FALL_SPEED);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, ["walls"]);
    }

    override public function moveCollideY(e:Entity) {
        //if(velocity.y < 0) {
            //velocity.y = -velocity.y;
        //}
        velocity.y = 0;
        return true;
    }

    private function animation() {
    }

    public function zeroVelocity() {
        velocity.x = 0;
        velocity.y = 0;
    }

    private function isOnGround() {
        return collide("walls", x, y + 1) != null;
    }
}
