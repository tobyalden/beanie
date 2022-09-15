package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;

class Level extends Entity
{
    public static inline var TILE_SIZE = 10;
    public static inline var MIN_WIDTH = 360;
    public static inline var MIN_HEIGHT = 360;

    public var entities(default, null):Array<Entity>;
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
            entities.push(new Player(Std.parseInt(player.att.x), Std.parseInt(player.att.y)));
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

