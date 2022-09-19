package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Controllable extends Entity
{
    public static inline var SPEED = 175;
    public static inline var GRAVITY = 900;
    public static inline var MAX_FALL_SPEED = 300;
    public static inline var MAX_RISE_SPEED = 200;
    public static inline var JUMP_POWER = 200;
    public static inline var JUMP_CANCEL_POWER = 40;
    public static inline var FLIGHT_POWER = 1800;

    public static var dismountedThisFrame:Bool = false;

    public var id:Int;
    public var rider:Controllable = null;
    public var riding:Controllable = null;

    private var velocity:Vector2;
    private var canFly:Bool;
    private var hitbox:Hitbox;

    public function setRider(newRider:Controllable) {
        rider = newRider;
        mask = new Hitbox(20, rider.height + 20, 0, cast(rider.mask, Hitbox).y - 20);
        //mask = new Hitbox(20, 40, 0, -20);
    }

    public function removeRider() {
        rider = null;
        mask = new Hitbox(20, 20);
    }

    public function new(x:Float, y:Float) {
        super(x, y);
        velocity = new Vector2();
        canFly = false;
    }

    override public function update() {
        super.update();
    }

    private function dismount() {
        riding.removeRider();
        riding.velocity.y = 0;
        riding.moveTo(x, bottom);
        canFly = false;
        riding = null;
        velocity.y = -Controllable.JUMP_POWER;
        Controllable.dismountedThisFrame = true;
    }

    private function unmountedMovement() {
        if(isOnGround()) {
            velocity.x = 0;
            velocity.y = 0;
        }
        else {
            velocity.y += GRAVITY * HXP.elapsed;
            velocity.y = MathUtil.clamp(velocity.y, -MAX_RISE_SPEED, MAX_FALL_SPEED);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, ["walls"]);
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
                canFly = false;
            }
        }
        else {
            var gravity:Float = GRAVITY;
            if(Math.abs(velocity.y) < JUMP_CANCEL_POWER) {
                gravity *= 0.5;
            }
            velocity.y += gravity * HXP.elapsed;
            if(Input.check("jump") && canFly) {
                velocity.y -= FLIGHT_POWER * HXP.elapsed;
            }
            else if(Input.released("jump")) {
                canFly = true;
                velocity.y = Math.max(velocity.y, -JUMP_CANCEL_POWER);
            }
            velocity.y = MathUtil.clamp(velocity.y, -MAX_RISE_SPEED, MAX_FALL_SPEED);
        }
        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, ["walls"]);
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = 0;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(velocity.y < 0) {
            velocity.y = -velocity.y;
        }
        return true;
    }

    private function isOnGround() {
        return collide("walls", x, y + 1) != null;
    }

    public function zeroVelocity() {
        velocity.x = 0;
        velocity.y = 0;
    }
}

