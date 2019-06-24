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
module api.common;

/++
    Enum of valid status codes that can be returned from the API
+/
enum StatusCode : string {
    StatusOK = "ok",
    StatusInvalid = "invalid",
    StatusDenied = "access_denied"
}

// A log in token is a string
alias Token = string;

/++
    A status without associated data.
+/
struct Status {
    /++
        The status code defining what error has happened
    +/
    StatusCode status;
}

/++
    A status is the basic container for API callback information.
+/
struct StatusT(T) {
    /++
        The status code defining what error has happened
    +/
    StatusCode status;

    /++
        The data for the status
    +/
    T data;
}

/++
    Formats ids
    IDs can contain:
     * Alpha Numeric Characters
     * _
     * -
     * .

    Spaces will automatically be converted to _
    Other characters will be discarded
+/
string formatId(string id) {
    import std.uni : isAlphaNum;
    string outId;
    foreach(c; id) {
        switch(c) {
            case ' ':
                outId ~= "_";
                break;
            case '_':
            case '-':
            case '.':
                outId ~= c;
                break;
            default:
                if (isAlphaNum(c)) {
                    outId ~= c;
                }
                break;
        }
    }
    return outId;
}