module session;
import std.variant;
import std.datetime;

__gshared SessionManagerImpl SESSIONS;

/++
    Creates a duration that is for this website's purpose practically infinite
+/
Duration practicallyInfinite() {
    // Returns a duration of 191553.629 years
    return 9_999_999.weeks;
}

/++
    Gets the current DateTime
+/
DateTime now() {
    return cast(DateTime)Clock.currTime()(new UTC());
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

    /++
        Creates a new session for use with opIndex
    +/
    Session* createSession(string token, Duration lifetime) {
        import std.base64 : Base64;

        // If session is already in store we don't need to add it twice.
        if (token in sessions) return null;

        // Create session and return it
        DateTime nowTime = now();
        sessions[token] = Session(Base64.encode(token), lifetime, nowTime, nowTime, []);
        return &sessions[token];
    }

    /++
        Updates the session manager by removing dead sessions
    +/
    void update() {
        DateTime nowTime = now();

        foreach(token, session; sessions) {

            // Check if the current time is over the session keep alive time + the max lifetime of a session
            // The session keep alive time = the last time the user used the session
            if (nowTime.total!"hours" > (session.keepAlive+session.lifetime).total!"hours") {
                sessions.remove(token);
            }
        }
    }
}