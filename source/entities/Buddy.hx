package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Buddy extends Controllable
{
    private var sprite:Spritemap;

    public function new(x:Float, y:Float, id:Int) {
        super(x, y);
        this.id = id;
        type = "buddy";
        hitbox = new Hitbox(20, 20);
        mask = hitbox;
        sprite = new Spritemap("graphics/buddy.png", 20, 20);
        sprite.add("idle", [0]);
        graphic = sprite;
    }

    override public function update() {
        //trace('buddy ${id}: rider: ${rider}. riding: ${riding}');

        var buddy = collide("buddy", x, y);
        if(buddy != null && id != cast(buddy, Controllable).id) {
            if(
                riding == null
                && rider != null
                && (rider.id != cast(buddy, Controllable).id)
            ) {
                //trace('buddy ${id}: collided with ${cast(buddy, Buddy).id}.');
                riding = cast(buddy, Controllable);
                riding.setRider(this);
                mask = new Hitbox(20, 20);
                collidable = false;
            }
        }
        if(rider == null) {
            unmountedMovement();
        }
        else {
            // Buddies can't move without something riding them
            if(riding == null) {
                movement();
            }
            else if (riding.riding == null) {
                if(Input.check("up") && Input.pressed("jump") && !Controllable.dismountedThisFrame) {
                    dismount();
                    collidable = true;
                }
            }
        }
        animation();
        super.update();
    } 

    private function animation() {
    }
}
