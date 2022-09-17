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
        return '${mapX}x${mapY}';
    }

    static public function fromKey(key:String):MapCoordinates {
        var parts = key.split('x');
        return {mapX: Std.parseInt(parts[0]), mapY: Std.parseInt(parts[1])};
    }
}

class GameScene extends Scene
{
    public static inline var DEBUG_MOVE_SPEED = 300;

    private var currentCoordinates:MapCoordinates;
    private var currentLevel:Level;
    private var levelToUnload:Level = null;
    private var ui:UI;
    private var player:Player;

    override public function begin() {
        Data.load(Main.SAVE_FILE_NAME);
        ui = add(new UI());
        ui.showDebugMessage("GAME START");

        var savedCoordinates = Data.read("playerCoordinates");
        var savedPosition = Data.read("playerPosition");
        if(savedCoordinates != null && savedPosition != null) {
            currentCoordinates = {mapX: savedCoordinates.mapX, mapY: savedCoordinates.mapY};
            loadLevel(currentCoordinates);
            player = add(new Player(savedPosition.x, savedPosition.y));
            ui.showDebugMessage("PLAYER LOCATION LOADED");
        }
        else {
            currentCoordinates = {mapX: 1000, mapY: 1000};
            loadLevel(currentCoordinates);
            player = add(new Player(currentLevel.playerStart.x, currentLevel.playerStart.y));
            ui.showDebugMessage("GAME START");
        }
    }

    override public function update() {
        camera.x = currentCoordinates.mapX * HXP.width;
        camera.y = currentCoordinates.mapY * HXP.height;
        if(levelToUnload != null) {
            for(entity in levelToUnload.entities) {
                if(Type.getSuperClass(Type.getClass(entity)) == Controllable && cast(entity, Controllable).rider != null) {
                    continue;
                }
                remove(entity);
            }
            remove(levelToUnload);
            levelToUnload = null;
        }
        var oldCoordinates:MapCoordinates = {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY};
        currentCoordinates = getCurrentCoordinates();
        if(isTransition(oldCoordinates) && levelExists(currentCoordinates)) {
            if(levelExists(oldCoordinates)) {
                levelToUnload = currentLevel;
            }
            if(levelExists(currentCoordinates)) {
                loadLevel(currentCoordinates);
            }
        }
        if(player.riding != null) {
            player.moveTo(player.riding.x, player.riding.y - player.height);
            var buddyAtBottom = player.riding;
            while(buddyAtBottom.riding != null) {
                buddyAtBottom.moveTo(buddyAtBottom.riding.x, buddyAtBottom.riding.y - buddyAtBottom.height);
                buddyAtBottom = buddyAtBottom.riding;
            }
        }
        super.update();
        debug();
    }

    public function levelExists(coordinates:MapCoordinates) {
        return Assets.exists('levels/${coordinates.toKey()}.oel');
    }

    public function loadLevel(coordinates:MapCoordinates) {
        var level = new Level(coordinates.toKey());
        level.offset(coordinates);
        currentLevel = add(level);
        for(entity in currentLevel.entities) {
            if(Type.getSuperClass(Type.getClass(entity)) == Controllable) {
                var controllables:Array<Entity> = [];
                getClass(Controllable, controllables);
                var doNotLoad = false;
                for(controllable in controllables) {
                    if(cast(entity, Controllable).id == cast(controllable, Controllable).id) {
                        doNotLoad = true;
                        break;
                    }
                }
                if(doNotLoad) {
                    trace('not loading entity with duplicate id ${cast(entity, Controllable).id}');
                    continue;
                }
            }
            add(entity);
        }
    }

    public function isTransition(oldCoordinates:MapCoordinates) {
        if(oldCoordinates.toKey() == currentCoordinates.toKey()) {
            return false;
        }
        return true;
    }

    private function debug() {
        ui.roomInfo.text = '[${currentCoordinates.mapX}, ${currentCoordinates.mapY}]';

        var isDebugMoving = Key.check(Key.DIGIT_9) || Key.check(Key.DIGIT_0);
        if(isDebugMoving) {
            player.active = false;
            player.graphic.alpha = 0.8;
        }
        else {
            player.active = true;
            player.graphic.alpha = 1;
        }

        // Camera
        if(Key.check(Key.DIGIT_1)) {
            camera.scale = 0.33;
            camera.x = (currentCoordinates.mapX - 1) * HXP.width;
            camera.y = (currentCoordinates.mapY - 1) * HXP.height;
        }
        else {
            camera.scale = 1;
        }

        // Debug movement (screen by screen)
        if(Key.check(Key.DIGIT_0)) {
            player.zeroVelocity();
            if(Key.pressed(Key.A)) {
                player.x -= HXP.width;
            }
            if(Key.pressed(Key.D)) {
                player.x += HXP.width;
            }
            if(Key.pressed(Key.W)) {
                player.y -= HXP.height;
            }
            if(Key.pressed(Key.S)) {
                player.y += HXP.height;
            }
        }

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
        }

        // Resetting, saving, and loading
        if(Key.pressed(Key.R)) {
            Data.clear();
            HXP.scene = new GameScene();
        }
        if(Key.pressed(Key.S)) {
            savePlayerLocation();
            ui.showDebugMessage("PLAYER LOCATION SAVED");
        }
        if(Key.pressed(Key.L)) {
            HXP.scene = new GameScene();
        }
    }

    private function savePlayerLocation() {
        Data.write("playerCoordinates", {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY});
        Data.write("playerPosition", {x: player.x, y: player.y});
        Data.save(Main.SAVE_FILE_NAME);
    }

    private function getCurrentCoordinates():MapCoordinates {
        return {
            mapX: Std.int(Math.floor(player.centerX / HXP.width)),
            mapY: Std.int(Math.floor(player.centerY / HXP.height))
        };
    }
}
