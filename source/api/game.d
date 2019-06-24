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
import vibe.db.mongo.collection : QueryFlags;
import vibe.db.mongo.cursor : MongoCursor;

/++
    A Game
+/
@trusted
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
    @name("name")
    string gameName;

    /++
        Description of game
    +/
    string description;

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

    this(string id, string name, string description, string adminId) {
        this.id = id;
        this.gameName = name;
        this.description = description;
        this.approved = false;
        this.admins ~= adminId;
    }
}

Game getGame(string gameId) {
    return DATABASE["speedrun.games"].findOne!Game(["_id": gameId]);
}

MongoCursor!Game searchGames(string query, int page = 0, int countPerPage = 20, bool showPending = false) {

    if (!showPending) {
        return DATABASE["speedrun.games"].find!Game(
            [
                "$and": [
                    "$or": [
                        ["_id": [ "$regex": query ]],
                        ["name": [ "$regex": query ]],
                        ["description": [ "$regex": query ]]
                    ]
                ]
            ],
            null, 
            QueryFlags.None, 
            page*countPerPage, 
            countPerPage);
    }
    return DATABASE["speedrun.games"].find!Game(
        [
            "$or": [
                ["_id": [ "$regex": query ]],
                ["name": [ "$regex": query ]],
                ["description": [ "$regex": query ]]
            ]
        ], 
        null, 
        QueryFlags.None, 
        page*countPerPage, 
        countPerPage);
}

/++
    Creates a new UNAPPROVED game
+/
Game newGame(string id, string displayName, string description, string admin) {
    string aid = id.formatId();

    if (DATABASE["speedrun.games"].count(["_id": id]) > 0) return null;
    Game game = new Game(aid, displayName, description, admin);
    DATABASE["speedrun.games"].insert(game);
    return game;
}

/++
    Approves game
+/
bool acceptGameFromId(string id) {
    Game game = getGame(id);
    if (game is null) return false;
    game.approved = true;
    DATABASE["speedrun.games"].update(["_id": id], game);
    return true;
}

void denyGameFromId(string id) {
    DATABASE["speedrun.games"].remove(["_id": id]);
}

struct GameCreationData {
    string token;
    string id;
    string name;
    string description;
}

@path("/games")
interface IGameEndpoint {
    /++
        Get game info
    +/
    @method(HTTPMethod.GET)
    @path("/:gameId")
    StatusT!Game game(string _gameId);

    /++
        Search for games
    +/
    @method(HTTPMethod.GET)
    @path("/search/:page")
    @queryParam("pgCount", "pgCount")
    @queryParam("showPending", "showPending")
    @queryParam("query", "query")
    StatusT!(Game[]) search(string query, int _page = 0, int pgCount = 20, bool showPending = false);

    /++
        Creates a new game
    +/
    @method(HTTPMethod.POST)
    @path("/:gameId")
    @bodyParam("data")
    Status createGame(string _gameId, GameCreationData data);

    /++
        === Moderator+ ===
        
        Accepts the pending game, if any.
    +/
    @method(HTTPMethod.POST)
    @path("/accept/:gameId")
    @bodyParam("token")
    Status acceptGame(string _gameId, string token);

    /++
        === Moderator+ ===
        
        Denies the pending game, if any.

        This will delete the game from the server.
    +/
    @method(HTTPMethod.POST)
    @path("/deny/:gameId")
    @bodyParam("token")
    Status denyGame(string _gameId, string token);
}

class GameEndpoint : IGameEndpoint {

    StatusT!Game game(string _gameId) {
        Game game = getGame(_gameId);
        return StatusT!Game(game !is null ? StatusCode.StatusOK : StatusCode.StatusInvalid, game);
    }

    StatusT!(Game[]) search(string query, int _page = 0, int pgCount = 20, bool showPending = false) {
        Game[] games;
        foreach(game; searchGames(query, _page, pgCount, showPending)) {
            games ~= game;
        }
        return StatusT!(Game[])(StatusCode.StatusOK, games);
    }

    Status createGame(string _gameId, GameCreationData data) {
        // Make sure the token is valid
        if (!SESSIONS.isValid(data.token)) 
            return Status(StatusCode.StatusDenied);

        // Make sure Game DOES NOT exists.
        if (getGame(_gameId) !is null) return Status(StatusCode.StatusInvalid);


        Game game = newGame(_gameId, data.name, data.description, SESSIONS[data.token].user);
        return game !is null ? Status(StatusCode.StatusOK) : Status(StatusCode.StatusInvalid);
    }

    Status acceptGame(string _gameId, string token) {
        // Make sure the token is valid
        if (!SESSIONS.isValid(token)) 
            return Status(StatusCode.StatusDenied);
        
        // Make sure the game exists
        if (getGame(_gameId) is null) return Status(StatusCode.StatusInvalid);

        // Make sure the user has the permissions to accept the CSS
        User user = getUser(SESSIONS[token].user);
        if (user.power < Powers.Mod) 
            return Status(StatusCode.StatusDenied);

        acceptGameFromId(_gameId);
        return Status(StatusCode.StatusOK);
    }

    Status denyGame(string _gameId, string token) {
        // Make sure the token is valid
        if (!SESSIONS.isValid(token)) 
            return Status(StatusCode.StatusDenied);
        
        // Make sure the game exists
        if (getGame(_gameId) is null) return Status(StatusCode.StatusInvalid);

        // Make sure the user has the permissions to accept the CSS
        User user = getUser(SESSIONS[token].user);
        if (user.power < Powers.Mod) 
            return Status(StatusCode.StatusDenied);

        denyGameFromId(_gameId);
        return Status(StatusCode.StatusOK);
    }
}