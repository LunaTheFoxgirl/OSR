/+
    Copyright © Clipsey 2019
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
+/
module api.game;
import vibe.web.rest;
import vibe.data.serialization;
import db;
import session;
import api.common;
import api.user;

/++

+/
class Game {
    /++
        ID of the game
    +/
    @name("_id")
    string id;

    /++
        Wether this game has been approved
    +/
    bool approved;

    /++
        Name of the game
    +/
    string name;

    /++
        List of admins
    +/
    string[] admins;

    /++
        List of mods
    +/
    string[] mods;

    /++
        FullGame Categories
    +/
    string[] fgCategories;

    /++
        Individual Level Categories
    +/
    string[] ilCategories;

    /++
        Levels
    +/
    string[] levels;

    this() {}

    this(string id, string name, string adminId) {
        this.id = id;
        this.name = name;
        this.approved = false;
        this.admins ~= adminId;
    }
}

Game getGame(string gameId) {
    return DATABASE["speedrun.games"].findOne!Game(["_id": gameId]);
}

/++
    Creates a new UNAPPROVED game
+/
Game newGame(string id, string displayName, string admin) {
    string aid = id.formatId();

    if (DATABASE["speedrun.games"].count!Game(["_id": aid]) > 0) return null;
    Game game = new Game(aid, displayName, admin);
    DATABASE["speedrun.games"].insert(game);
}

interface IGameEndpoint {

}