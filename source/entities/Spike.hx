package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;

class Spike extends Entity
{
    public static inline var FLOOR = 0;
    public static inline var CEILING = 1;
    public static inline var LEFT_WALL = 2;
    public static inline var RIGHT_WALL = 3;

    private var orientation:Int;

    public function new(x:Float, y:Float, orientation:Int, length:Int)
    {
        super(x, y);
        this.orientation = orientation;
        type = "hazard";
        var sprite:TiledImage;
        if(orientation == FLOOR) {
            sprite = new TiledImage("graphics/spike_floor.png", length, 10);
            mask = new Hitbox(length, 10);
        }
        else if(orientation == CEILING) {
            sprite = new TiledImage("graphics/spike_ceiling.png", length, 10);
            mask = new Hitbox(length, 10);
        }
        else if(orientation == LEFT_WALL) {
            sprite = new TiledImage("graphics/spike_left_wall.png", 10, length);
            mask = new Hitbox(10, length);
        }
        else {
            sprite = new TiledImage("graphics/spike_right_wall.png", 10, length);
            mask = new Hitbox(10, length);
        }
        graphic = sprite;
    }
}

