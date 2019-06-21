module db;
import mondo;
import bsond;

__gshared Mongo DATABASE;

shared static this() {
    DATABASE = new Mongo("mongodb://localhost");
}