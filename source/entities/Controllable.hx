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

    public var velocity:Vector2;
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

    private function countTotalRiders() {
        var totalRiders = 0;
        var lastRider = rider;
        while(lastRider != null) {
            lastRider = lastRider.rider;
            totalRiders++;
        }
        return totalRiders;
    }

    private function getRiderWeightModifier() {
        return 1 - 0.1 * countTotalRiders();
    }

    public function new(x:Float, y:Float) {
        super(x, y);
        velocity = new Vector2();
        canFly = false;
    }

    override public function update() {
        super.update();
    }

    public function getAllRiding() {
        var allRiding:Array<Controllable> = [this];
        var nextRiding = riding;
        while(nextRiding != null) {
            allRiding.push(nextRiding);
            nextRiding = nextRiding.riding;
        }
        return allRiding;
    }

    //public function getBottommostMount() {
        //var bottommostMount = this;
        //var nextRiding = riding;
        //while(nextRiding != null) {
            //bottommostMount = nextRiding;
            //nextRiding = nextRiding.riding;
        //}
        //return bottommostMount;
    //}

    private function detachAllRiding() {
        var nextRiding = riding;
        var allRiding:Array<Controllable> = [];
        var releaseVelocityX:Float = 0;
        while(nextRiding != null) {
            allRiding.push(nextRiding);
            nextRiding.removeRider();
            nextRiding.collidable = true;
            var storedRiding = nextRiding.riding;
            nextRiding.riding = null;
            var releaseVelocityX = nextRiding.velocity.x;
            nextRiding = storedRiding;
        }
        for(controllable in allRiding) {
            controllable.velocity.x = allRiding[allRiding.length - 1].velocity.x;
        }
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
            velocity.x = -SPEED * getRiderWeightModifier();
        }
        else if(Input.check("right")) {
            velocity.x = SPEED * getRiderWeightModifier();
        }
        else {
            velocity.x = 0;
        }

        if(isOnGround()) {
            velocity.y = 0;
            if(Input.pressed("jump")) {
                velocity.y = -JUMP_POWER * getRiderWeightModifier();
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
                velocity.y -= FLIGHT_POWER * getRiderWeightModifier() * HXP.elapsed;
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

    private function explode(numExplosions:Int) {
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
}
