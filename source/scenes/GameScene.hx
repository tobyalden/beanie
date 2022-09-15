package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;

@:structInit class MapCoordinates {
    public var mapX:Int;
    public var mapY:Int;

    public function toKey():String {
        return '$mapX-$mapY';
    }

    static public function fromKey(key:String):MapCoordinates {
        var parts = key.split('-');
        return {mapX: Std.parseInt(parts[0]), mapY: Std.parseInt(parts[1])};
    }
}

class GameScene extends Scene
{
    public static inline var DEBUG_MOVE_SPEED = 300;

    private var currentCoordinates:MapCoordinates;
    private var ui:UI;
    private var player:Player;

    override public function begin() {
        currentCoordinates = {mapX: 0, mapY: 0};
        ui = add(new UI());
        ui.showDebugMessage("GAME START");
        var level = new Level("level");
        add(level);
        for(entity in level.entities) {
            if(Type.getClass(entity) == Player) {
                player = cast(entity, Player);
            }
            add(entity);
        }
    }

    override public function update() {
        currentCoordinates = getCurrentCoordinates();
        debug();
        super.update();
        camera.x = Math.floor(player.centerX / HXP.width) * HXP.width;
        camera.y = Math.floor(player.centerY / HXP.height) * HXP.height;
    }

    private function debug() {
        ui.roomInfo.text = '[${currentCoordinates.mapX}, ${currentCoordinates.mapY}]';

        player.active = !Key.check(Key.DIGIT_9);

        // Debug movement (smooth)
        if(Key.check(Key.DIGIT_9)) {
            player.zeroVelocity();
            if(Key.check(Key.A)) {
                player.x -= DEBUG_MOVE_SPEED * HXP.elapsed;
            }
            if(Key.check(Key.D)) {
                player.x += DEBUG_MOVE_SPEED * HXP.elapsed;
            }
            if(Key.check(Key.W)) {
                player.y -= DEBUG_MOVE_SPEED * HXP.elapsed;
            }
            if(Key.check(Key.S)) {
                player.y += DEBUG_MOVE_SPEED * HXP.elapsed;
            }
            player.graphic.alpha = 0.7;
        }
        else {
            player.graphic.alpha = 1;
        }
    }

    private function getCurrentCoordinates():MapCoordinates {
        return {
            mapX: Std.int(Math.floor(player.centerX / HXP.width)),
            mapY: Std.int(Math.floor(player.centerY / HXP.height))
        };
    }
}
