module db;
import mondo;
import bsond;

__gshared Db DATABASE;

shared static this() {
    auto mongo = new Mongo("mongodb://localhost");

    DATABASE = new Db(new Mongo(mongo["speedrun"]));
}