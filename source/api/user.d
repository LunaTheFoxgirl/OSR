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
module api.user;
import api.common;
import mondo;
import bsond;
import crypt;
import db;
import std.range;
import std.algorithm;

/++
    A user
+/
struct User {
private:
    BsonObject _bson;

public:

    /// Gets the user's user name
    @property string username() { return _bson["username"].as!string; }

    /// Gets display name
    @property string displayName() { return _bson["display_name"].as!string; }

    /// Sets display name
    @property void displayName(string name) { return _bson["display_name"] = name; }

    /// Gets authentication info
    @property UserAuth auth() { return UserAuth(_bson);  }

    /// Sets authentication info
    @property void auth(UserAuth auth) {
        _bson["/auth/pwd"] = auth.hash();
        _bson["/auth/salt"] = auth.salt();
    }

    /// saving for mongo
    @property auto bson() const { 
        return _bson; 
    }

    /// Constructor for mongo
    this(BsonObject obj) {
        _bson = obj;
    }
}

/++
    Get user from database
+/
User getUser(string username) {
    return DATABASE.speedrun.users.findOne!User(Query.init.filterByUsername(username));
}

auto filterByUsername(Query q, in string name) { q.conditions["username"] = name; return q; }

/++
    User authentication info
+/
struct UserAuth {
private:
    BsonObject _bson;

public:
    /++
        Salt for SCrypt hashed password
    +/
    @property string salt() { return _bson["/auth/salt"].as!string; }

    /++
        SCrypt hashed password
    +/
    @property string hash() { return _bson["/auth/pwd"].as!string; }


    /// saving for mongo
    @property auto bson() const { return _bson; }

    /// Constructor for mongo
    this(BsonObject obj) {
        _bson = obj;
    }

    this(string password) {
        auto hashcomb = hashPassword(password);
        _bson["pwd"] = hashcomb.hash;
        _bson["salt"] = hashcomb.salt;
    }

    /++
        Verify that the password is correct
    +/
    bool verify(string password) {
        return verifyPassword(password, cast(ubyte[])this.hash, cast(ubyte[])this.salt);
    }
}

/++
    Endpoint for user managment
+/
interface IUserEndpoint {

    /++
        Logs in user
    +/
    StatusT!Token login(string username, string password);

    /++
        Logs out user
    +/
    Status logout(Token token);

    /++
        Registers a new user

        DO NOTE: 
        A user is not the same as a runner.
        A user will be converted to a runner when they post their first run.
    +/
    StatusT!Token register(User userinfo, string password);

    /++
        Endpoint changes user info
    +/
    Status update(string token, User data);

    /++
        Removes user from database with token.

        DO NOTE:
        Verify with password!
    +/
    Status rmuser(string token, string password);
}

/++
    Implementation of user endpoint
+/
class UserEndpoint : IUserEndpoint {
    StatusT!Token login(string username, string password) {
        return StatusT!Token(StatusCode.StatusOK, "ok");
    }

    Status logout(Token token) {
        return Status(StatusCode.StatusOK);
    }

    StatusT!Token register(User userinfo, string password) {
        return StatusT!Token(StatusCode.StatusOK, "ok");
    }

    Status update(string token, User data) {
        return Status(StatusCode.StatusOK);
    }

    Status rmuser(string token, string password) {
        return Status(StatusCode.StatusOK);
    }
}