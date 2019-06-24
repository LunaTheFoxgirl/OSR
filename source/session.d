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
module session;
import std.variant;
import std.datetime;

/++
    Memory session store
+/
__gshared SessionManagerImpl SESSIONS;

/++
    Creates a duration that is for this website's purpose practically infinite
+/
Duration practicallyInfinite() {
    // Returns a duration of 191553.629 years
    return 9_999_999.weeks;
}

Duration lifetimeFromLong(long value) {
    if (value == 0) return practicallyInfinite();
    return value.hnsecs;
}

/++
    Gets the current DateTime
+/
DateTime now() {
    return cast(DateTime)Clock.currTime(UTC());
}

/++
    A session is a container for session data for a user.
+/
struct Session {
    /++
        Token of the session
    +/
    string token;

    /++
        The username of the session owner
    +/
    string user;

    /++
        How long this session is alive for.
        
        Use practicallyInfinite to get a duration that is practically infinite.
    +/
    Duration lifetime;

    /++
        The time this session was created
    +/
    DateTime createTime;

    /++
        Last time this was marked to be kept alive.

        NOTE: set this to the same value as createTime on creation
    +/
    DateTime keepAlive;

    /++
        Variant data for the user,     
    +/
    Variant[string] data;
}

/++
    Implementation of a session manager.
+/
class SessionManagerImpl {
private:
    Session[string] sessions;

public:

    /++
        Get session from token via array index operator override.

        If session is not found this will return null.
    +/
    Session* opIndex(string token) {
        if (token !in sessions) return null;
        return &sessions[token];
    }

    Session* findUser(string username) {
        foreach(session; sessions) {
            if (session.user == username) return &session;
        }
        return null;
    }

    /++
        Get wether token is in session store via array binary in operator override.
    +/
    bool opBinary(string op = "in")(string idex){
        return (idex in sessions) !is null;
    }
    /++
        Get wether token is in session store via array binary in operator override.
    +/
    bool opBinaryRight(string op = "in")(string idex){
        return (idex in sessions) !is null;
    }

    bool isValid(string token) {
        return token !is null && token != "" && SESSIONS[token] !is null;
    }

    /++
        Creates a new session for use with opIndex
    +/
    Session* createSession(Duration lifetime) {
        import std.base64 : Base64URL;
        import secured.random;

        // Create session and return it
        DateTime nowTime = now();
        string token = Base64URL.encode(random(64));
        Session session;
        session.token = token;
        session.lifetime = lifetime;
        session.createTime = nowTime;
        session.keepAlive = nowTime;

        sessions[token] = session;
        return &sessions[token];
    }

    /++
        Kill a session by removing it from the active session store.
    +/
    void kill(string token) {
        if (token in sessions) sessions.remove(token);
    }

    /++
        Updates the session manager by removing dead sessions
    +/
    void update() {
        DateTime nowTime = now();

        foreach(token, session; sessions) {

            // Check if the current time is over the session keep alive time + the max lifetime of a session
            // The session keep alive time = the last time the user used the session

            Duration now = (cast(Duration)nowTime);
            Duration then = (cast(Duration)(session.keepAlive+session.lifetime));

            if (now.total!"hours" > then.total!"hours") {
                sessions.remove(token);
            }
        }
    }
}