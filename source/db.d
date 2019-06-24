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
module db;
import vibe.db.mongo.client;
public import vibe.db.mongo.database;
import vibe.db.mongo.mongo;

__gshared Database DATABASE;

class Database {
private:
    MongoClient client;

public:
    MongoCollection opIndex(string index) {
        return client.getCollection(index);
    }

    this(string connString) {
        this.client = connectMongoDB(connString);
    }
}

shared static this() {
    DATABASE = new Database("mongodb://127.0.0.1");
}