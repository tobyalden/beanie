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

    public function equals(otherCoordinates:MapCoordinates) {
        return mapX == otherCoordinates.mapX && mapY == otherCoordinates.mapY;
    }

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
    private var loadedLevels:Map<String, Level>;
    private var ui:UI;
    private var player:Player;

    override public function begin() {
        Data.load(Main.SAVE_FILE_NAME);
        ui = add(new UI());
        ui.showDebugMessage("GAME START");

        loadedLevels = [];

        var savedCoordinates = Data.read("playerCoordinates");
        var savedPosition = Data.read("playerPosition");
        if(savedCoordinates != null && savedPosition != null) {
            currentCoordinates = {mapX: savedCoordinates.mapX, mapY: savedCoordinates.mapY};
            player = add(new Player(savedPosition.x, savedPosition.y));
            ui.showDebugMessage("PLAYER LOCATION LOADED");

            // Load buddies
            var controllableIds:Array<Int> = Data.read("controllableIds", []);
            var playerAndBuddies:Array<Controllable> = [player];
            for(i in 0...controllableIds.length) {
                playerAndBuddies.push(new Buddy(player.x, player.y + 20 * i, controllableIds[i]));
            }
            for(i in 0...playerAndBuddies.length) {
                if(i < playerAndBuddies.length - 1) {
                    playerAndBuddies[i].riding = playerAndBuddies[i + 1];
                    playerAndBuddies[i + 1].setRider(playerAndBuddies[i]);
                    if(i > 0) {
                        playerAndBuddies[i].mask = new Hitbox(20, 20);
                        playerAndBuddies[i].collidable = false;
                    }
                }
                if(i > 0) {
                    add(playerAndBuddies[i]);
                }
            }

            loadLevels(currentCoordinates, controllableIds);
        }
        else {
            currentCoordinates = {mapX: 1000, mapY: 1000};
            loadLevels(currentCoordinates);
            var currentLevel = loadedLevels[currentCoordinates.toKey()];
            player = add(new Player(currentLevel.playerStart.x, currentLevel.playerStart.y));
            ui.showDebugMessage("GAME START");
        }
    }

    override public function update() {
        //trace('$loadedLevels');
        Controllable.dismountedThisFrame = false;
        camera.x = currentCoordinates.mapX * HXP.width;
        camera.y = currentCoordinates.mapY * HXP.height;
        var oldCoordinates:MapCoordinates = {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY};
        currentCoordinates = getCurrentCoordinates();
        if(!currentCoordinates.equals(oldCoordinates)) {
            loadLevels(currentCoordinates);
            unloadLevels(oldCoordinates, currentCoordinates);
        }
        super.update();
        if(player.riding != null) {
            var buddyAtBottom = player.riding;
            var allBuddies = [buddyAtBottom];
            while(buddyAtBottom.riding != null) {
                //buddyAtBottom.moveTo(buddyAtBottom.riding.x, buddyAtBottom.riding.y - buddyAtBottom.height);
                buddyAtBottom = buddyAtBottom.riding;
                allBuddies.push(buddyAtBottom);
            }
            allBuddies.reverse();
            for(buddy in allBuddies) {
                if(buddy.riding != null) {
                    buddy.moveTo(buddy.riding.x, buddy.riding.y - buddy.height);
                }
            }
            player.moveTo(player.riding.x, player.riding.y - player.height);
        }
        debug();
    }

    public function levelExists(coordinates:MapCoordinates) {
        return Assets.exists('levels/${coordinates.toKey()}.oel');
    }

    public function levelLoaded(coordinates:MapCoordinates) {
        return loadedLevels.exists(coordinates.toKey());
    }

    public function getCenterAndAdjacentCoordinates(centerCoordinates:MapCoordinates) {
        var allCoordinates:Array<MapCoordinates> = [
            centerCoordinates,
            {mapX: centerCoordinates.mapX - 1, mapY: centerCoordinates.mapY},
            {mapX: centerCoordinates.mapX + 1, mapY: centerCoordinates.mapY},
            {mapX: centerCoordinates.mapX, mapY: centerCoordinates.mapY - 1},
            {mapX: centerCoordinates.mapX, mapY: centerCoordinates.mapY + 1}
        ];
        return allCoordinates;
    }

    public function loadLevels(centerCoordinates:MapCoordinates, mountIds:Array<Int> = null) {
        for(coordinates in getCenterAndAdjacentCoordinates(centerCoordinates)) {
            if(!levelExists(coordinates) || levelLoaded(coordinates)) {
                continue;
            }
            var level = new Level(coordinates.toKey());
            level.offset(coordinates);
            add(level);
            loadedLevels[coordinates.toKey()] = level;
            for(entity in level.entities) {
                if(Type.getSuperClass(Type.getClass(entity)) == Controllable) {
                    if(mountIds != null && mountIds.indexOf(cast(entity, Controllable).id) != -1) {
                        continue;
                    }
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
    }

    public function unloadLevels(oldCoordinates:MapCoordinates, newCoordinates:MapCoordinates) {
        var oldCoordinateSet = getCenterAndAdjacentCoordinates(oldCoordinates);
        var newCoordinateSet = getCenterAndAdjacentCoordinates(newCoordinates);
        var coordinatesToUnload:Array<MapCoordinates> = [];
        for(oldCoordinateSetCheck in oldCoordinateSet) {
            var shouldUnload = true;
            for(newCoordinateSetCheck in newCoordinateSet) {
                if(oldCoordinateSetCheck.equals(newCoordinateSetCheck)) {
                    shouldUnload = false;
                    break;
                }
            }
            if(shouldUnload) {
                coordinatesToUnload.push(oldCoordinateSetCheck);
            }
        }

        for(coordinateToUnload in coordinatesToUnload) {
            if(levelLoaded(coordinateToUnload)) {
                remove(loadedLevels[coordinateToUnload.toKey()]);
                for(entity in loadedLevels[coordinateToUnload.toKey()].entities) {
                    if(Type.getSuperClass(Type.getClass(entity)) == Controllable && cast(entity, Controllable).rider != null) {
                        continue;
                    }
                    // TODO: will this crash if I remove an entity that's already been removed?
                    remove(entity);
                }
                loadedLevels.remove(coordinateToUnload.toKey());
            }
        }
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

        var controllables:Array<Entity> = [];
        var controllableIds:Array<Int> = [];
        getClass(Controllable, controllables);
        for(entity in controllables) {
            var controllable = cast(entity, Controllable);
            if(controllable.rider != null) {
                controllableIds.push(controllable.id);
            }
        }
        Data.write("controllableIds", controllableIds);

        Data.save(Main.SAVE_FILE_NAME);
    }

    private function getCurrentCoordinates():MapCoordinates {
        return {
            mapX: Std.int(Math.floor(player.centerX / HXP.width)),
            mapY: Std.int(Math.floor(player.centerY / HXP.height))
        };
    }
}
