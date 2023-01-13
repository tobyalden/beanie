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
        currentCoordinates = {mapX: 1000, mapY: 1000};
        ui = add(new UI());
        ui.showDebugMessage("GAME START");
        loadLevel(currentCoordinates);

        var savedCoordinates = Data.read("playerCoordinates");
        var savedPosition = Data.read("playerPosition");
        if(savedCoordinates != null && savedPosition != null) {
            currentCoordinates = {mapX: savedCoordinates.mapX, mapY: savedCoordinates.mapY};
            if(levelExists(currentCoordinates)) {
                loadLevel(currentCoordinates);
            }
            player = add(new Player(savedPosition.x, savedPosition.y));
            ui.showDebugMessage("PLAYER LOCATION LOADED");
        }
        else {
            currentCoordinates = {mapX: 1000, mapY: 1000};
            loadLevel(currentCoordinates);
            //player = add(new Player(currentLevel.playerStart.x, currentLevel.playerStart.y));
            player = add(new Player(currentCoordinates.mapX * Level.LEVEL_WIDTH + 100, currentCoordinates.mapY * Level.LEVEL_HEIGHT + 100));
            ui.showDebugMessage("GAME START");
        }
    }

    override public function update() {
        if(levelToUnload != null) {
            for(entity in levelToUnload.entities) {
                remove(entity);
            }
            remove(levelToUnload);
            levelToUnload = null;
        }
        var oldCoordinates:MapCoordinates = {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY};
        currentCoordinates = getCurrentCoordinates();
        if(isTransition(oldCoordinates) && levelExists(currentCoordinates)) {
            loadLevel(currentCoordinates);
        }
        super.update();
        camera.x = player.centerX - HXP.width / 2;
        camera.x = MathUtil.clamp(
            camera.x,
            currentCoordinates.mapX * Level.LEVEL_WIDTH,
            (currentCoordinates.mapX + 1) * Level.LEVEL_WIDTH - HXP.width
        );
        camera.y = currentCoordinates.mapY * HXP.height;
        debug();
    }

    public function levelExists(coordinates:MapCoordinates) {
        return Assets.exists('levels/${coordinates.toKey()}.oel');
    }

    public function loadLevel(coordinates:MapCoordinates) {
        var level = new Level(coordinates.toKey());
        level.offset(coordinates);
        levelToUnload = currentLevel;
        currentLevel = add(level);
        for(entity in currentLevel.entities) {
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
            camera.scale = 0.05;
            for(mapX in 0...4) {
                for(mapY in 0...16) {
                    loadLevel({mapX: 1000 + mapX, mapY: 1000 + mapY});
                    levelToUnload = null;
                }
            }
            camera.x = 1000 * Level.LEVEL_WIDTH;
            camera.y = 1000 * Level.LEVEL_HEIGHT;
        }
        else {
            camera.scale = 1;
        }

        if(Key.check(Key.DIGIT_0)) {
            // Debug movement (screen by screen)
            player.zeroVelocity();
            if(Key.pressed(Key.A)) {
                player.x -= Level.LEVEL_WIDTH;
            }
            if(Key.pressed(Key.D)) {
                player.x += Level.LEVEL_WIDTH;
            }
            if(Key.pressed(Key.W)) {
                player.y -= Level.LEVEL_HEIGHT;
            }
            if(Key.pressed(Key.S)) {
                player.y += Level.LEVEL_HEIGHT;
            }
        }
        else if(Key.check(Key.DIGIT_9)) {
            // Debug movement (smooth)
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
        else if(Key.pressed(Key.R)) {
            // Reset
            Data.clear();
            HXP.scene = new GameScene();
        }
        else if(Key.pressed(Key.S)) {
            // Save
            savePlayerLocation();
            ui.showDebugMessage("PLAYER LOCATION SAVED");
        }
        else if(Key.pressed(Key.L)) {
            // Load
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
            mapX: Std.int(Math.floor(player.centerX / Level.LEVEL_WIDTH)),
            mapY: Std.int(Math.floor(player.centerY / Level.LEVEL_HEIGHT))
        };
    }
}
