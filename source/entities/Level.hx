package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;
import scenes.GameScene;

class Level extends Entity
{
    public static inline var TILE_SIZE = 10;
    public static inline var MIN_WIDTH = 360;
    public static inline var MIN_HEIGHT = 360;

    public var entities(default, null):Array<Entity>;
    public var playerStart(default, null):Vector2 = null;
    private var walls:Grid;
    private var tiles:Tilemap;

    public function new(fileName:String) {
        super(0, 0);
        type = "walls";
        loadFromFile(fileName);
        updateGraphic();
    }

    override public function update() {
        super.update();
    }

    private function loadFromFile(fileName:String) {
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('levels/${fileName}.oel')));

        // Load walls
        walls = new Grid(
            Std.parseInt(xml.node.level.att.width),
            Std.parseInt(xml.node.level.att.height),
            TILE_SIZE,
            TILE_SIZE
        );
        walls.loadFromString(xml.node.level.node.solids.innerData, "", "\n");
        mask = walls;

        // Load entities
        entities = new Array<Entity>();
        for(player in xml.node.level.node.entities.nodes.player) {
            playerStart = new Vector2(Std.parseInt(player.att.x), Std.parseInt(player.att.y));
        }
        var controllableId = 1;
        for(buddy in xml.node.level.node.entities.nodes.buddy) {
            entities.push(new Buddy(Std.parseInt(buddy.att.x), Std.parseInt(buddy.att.y), controllableId));
            controllableId++;
        }
        for(spikeFloor in xml.node.level.node.entities.nodes.spike_floor) {
            entities.push(new Spike(
                Std.parseInt(spikeFloor.att.x),
                Std.parseInt(spikeFloor.att.y),
                Spike.FLOOR,
                Std.parseInt(spikeFloor.att.width)
            ));
        }
        for(spikeCeiling in xml.node.level.node.entities.nodes.spike_ceiling) {
            entities.push(new Spike(
                Std.parseInt(spikeCeiling.att.x),
                Std.parseInt(spikeCeiling.att.y),
                Spike.CEILING,
                Std.parseInt(spikeCeiling.att.width)
            ));
        }
        for(spikeLeftWall in xml.node.level.node.entities.nodes.spike_left_wall) {
            entities.push(new Spike(
                Std.parseInt(spikeLeftWall.att.x),
                Std.parseInt(spikeLeftWall.att.y),
                Spike.LEFT_WALL,
                Std.parseInt(spikeLeftWall.att.height)
            ));
        }
        for(spikeRightWall in xml.node.level.node.entities.nodes.spike_right_wall) {
            entities.push(new Spike(
                Std.parseInt(spikeRightWall.att.x),
                Std.parseInt(spikeRightWall.att.y),
                Spike.RIGHT_WALL,
                Std.parseInt(spikeRightWall.att.height)
            ));
        }
    }

    public function offset(coordinates:MapCoordinates) {
        moveTo(coordinates.mapX * HXP.width, coordinates.mapY * HXP.height);
        for(entity in entities) {
            entity.x += coordinates.mapX * HXP.width;
            entity.y += coordinates.mapY * HXP.height;
            if(Type.getSuperClass(Type.getClass(entity)) == Controllable) {
                cast(entity, Controllable).id += coordinates.mapX * 100 + coordinates.mapY * 10000;
            }
        }
        if(playerStart != null) {
            playerStart.x += coordinates.mapX * HXP.width;
            playerStart.y += coordinates.mapY * HXP.height;
        }
    }

    public function updateGraphic() {
        tiles = new Tilemap(
            'graphics/tiles.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(walls.getTile(tileX, tileY)) {
                    tiles.setTile(tileX, tileY, 0);
                }
            }
        }
        graphic = tiles;
    }
}

