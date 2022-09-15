package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;

class UI extends Entity
{
    public var roomInfo:Text;
    public var debugMessage:Text;
    public var debugMessageTimer:Alarm;

    public function new() {
        super(0, 0);
        layer = -10;

        roomInfo = new Text("debug", {size: 16, color: 0x00FF00});
        roomInfo.y = HXP.height - roomInfo.height - 5;

        debugMessage = new Text("DEBUG MODE", {size: 16, color: 0x00FF00});
        debugMessage.y = roomInfo.y - debugMessage.height;
        debugMessageTimer = new Alarm(1, function() {
            debugMessage.text = "";
        });
        addTween(debugMessageTimer, true);

        var allSprites = new Graphiclist([roomInfo, debugMessage]);
        graphic = allSprites;
        graphic.scrollX = 0;
        graphic.scrollY = 0;
    }

    public function showDebugMessage(message:String) {
        debugMessage.text = message;
        debugMessageTimer.start();
    }

    override public function update() {
        super.update();
    }
}
