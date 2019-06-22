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
import crypt;
import db;
import std.range;
import std.algorithm;
import session;
import vibe.web.rest;
import std.algorithm;
import vibe.data.serialization;
import vibe.data.bson;
import std.base64;

/++
    User authentication info
+/
struct UserAuth {
public:
    /++
        Salt of password
    +/
    string salt;

    /++
        Hash of password
    +/
    string hash;

    /++
        Create new userauth instance from password

        Gets hashed with scrypt.
    +/
    this(string password) {
        auto hashcomb = hashPassword(password);
        hash = Base64.encode(hashcomb.hash);
        salt = Base64.encode(hashcomb.salt);
    }

    /++
        Verify that the password is correct
    +/
    bool verify(string password) {
        return verifyPassword(password, Base64.decode(this.hash), Base64.decode(this.salt));
    }
}

/++
    A user
+/
@trusted
class User {
public:
    /++
        User's username (used during login)
    +/
    @name("_id")
    string username;

    /++
        User's email (used during registration and to send notifications, etc.)
    +/
    @name("email")
    string email;

    /++
        User's display name
    +/
    @name("display_name")
    string displayName;

    /++
        Wether the user has verified their email
    +/
    @name("verified")
    bool verified;

    /++
        User's authentication info
    +/
    @name("auth")
    UserAuth auth;

    /++
        For serialized instances
    +/
    this() { }

    /++
        User on account creation
    +/
    this(string username, string email, UserAuth auth) {
        this.username = username;
        this.email = email;
        this.displayName = username;
        this.verified = false;
        this.auth = auth;
    }
}

/++
    Get user from database
+/
@trusted User getUser(string username) {
    return DATABASE["speedrun.users"].findOne!User(["_id": username]);
}

/++
    Returns true if there's a user with specified username
+/
@trusted bool nameTaken(string username) {
    return DATABASE["speedrun.users"].count(["_id": username]) > 0;
}

/++
    Returns true if there's a user with specified username
+/
@trusted bool emailTaken(string email) {
    return DATABASE["speedrun.users"].count(["email": email]) > 0;
}

/++
    Creates a new user and returns the user object.
+/
@trusted User createUser(string username, RegData data) {
    if (username.nameTaken) return null;

    DATABASE["speedrun.users"].insert(new User(username, data.email, UserAuth(data.password)));
    return getUser(username);
}

/++
    Data used for authentication (logging in)
+/
struct AuthData {
    /// Password to log in with
    string password;

    /// Lifetime of the session you want
    @optional
    long lifetime = 0;
}

/++
    Data used for registration
+/
struct RegData {
    /// Email for notifications, etc.
    string email;

    /// Password to log in with
    string password;

    /// Lifetime of the session you want
    @optional
    long lifetime = 0;
}

/++
    Endpoint for user managment
+/
@path("/auth")
@trusted
interface IAuthenticationEndpoint {

    /++
        Logs in user
    +/
    @method(HTTPMethod.POST)
    @path("/login/:username")
    @bodyParam("data")
    StatusT!Token login(string _username, AuthData data);

    /++
        Logs out user
    +/
    @method(HTTPMethod.POST)
    @path("/logout")
    @bodyParam("token")
    Status logout(Token token);

    /++
        Registers a new user

        DO NOTE: 
        A user is not the same as a runner.
        A user will be converted to a runner when they post their first run.
    +/
    @method(HTTPMethod.POST)
    @path("/register/:username")
    @bodyParam("data")
    StatusT!Token register(string _username, RegData data);

    /++
        Verifies a new user allowing them to create/post runs, etc.
    +/
    @method(HTTPMethod.POST)
    @path("/verify")
    @bodyParam("verifykey")
    Status verify(string verifykey);
}

/++
    User endpoint for user settings
+/
@path("/users")
@trusted
interface IUserEndpoint {

    /++
        Endpoint changes user info
    +/
    @path("/update")
    Status update(string token, User data);

    /++
        Removes user from database with token.

        DO NOTE:
        Verify with password!
    +/
    @path("/rmuser")
    Status rmuser(string token, string password);

}

/++
    Implementation of auth endpoint
+/
@trusted
class AuthenticationEndpoint : IAuthenticationEndpoint {
    StatusT!Token login(string username, AuthData data) {

        // Get user instance, if user doesn't exist return status invalid
        User userPtr = getUser(username);
        if (userPtr is null) return StatusT!Token(StatusCode.StatusInvalid, null);

        // Update and destroy old sessions
        SESSIONS.update();

        // Verify password
        if (!userPtr.auth.verify(data.password)) return StatusT!Token(StatusCode.StatusDenied, null);

        // If the user already has a running session just send that
        // Otherwise create a new session
        if (SESSIONS.findUser(username) !is null) {
            return StatusT!Token(StatusCode.StatusOK, SESSIONS.findUser(username).token);
        }
        return StatusT!Token(StatusCode.StatusOK, SESSIONS.createSession(data.lifetime.lifetimeFromLong).token);
    }

    Status logout(Token token) {
        if (token in SESSIONS) {
            SESSIONS.kill(token);
        }
        return Status(StatusCode.StatusInvalid);
    }

    StatusT!Token register(string username, RegData data) {
        if (nameTaken(username)) return StatusT!Token(StatusCode.StatusInvalid, "name_taken");
        if (emailTaken(data.email)) return StatusT!Token(StatusCode.StatusInvalid, "email_taken");
        createUser(username, data);
        return login(username, AuthData(data.password, data.lifetime));
    }

    Status verify(string verifykey) {
        // TODO: verify auser
        return Status(StatusCode.StatusOK);
    }
}

class UserEndpoint : IUserEndpoint {
    Status update(string token, User data) {
        return Status(StatusCode.StatusOK);
    }

    Status rmuser(string token, string password) {
        return Status(StatusCode.StatusOK);
    }
}
