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
module crypt;
import secured.kdf;
import secured.random;
import config;

struct HashCombination {
    ubyte[] hash;
    ubyte[] salt;
}

/++
    Hash password using a secure randomly generated salt
+/
HashCombination hashPassword(string password) {
    return hashPassword(password, random(SCRYPT_SALT_LENGTH));
}

/++
    Hash a password using salt
+/
HashCombination hashPassword(string password, ubyte[] salt) {
    HashCombination combination;
    combination.salt = salt;
    combination.hash = scrypt_ex(
                            cast(ubyte[])password, 
                            salt, 
                            SCRYPT_N, 
                            SCRYPT_R, 
                            SCRYPT_P, 
                            SCRYPT_MAX_MEM, 
                            SCRYPT_LENGTH);
    
    return combination;
}

/++
    Verify a password's hash
+/
bool verifyPassword(string password, ubyte[] hash, ubyte[] salt) {
    HashCombination hashcomb = hashPassword(password, salt);
    return hashcomb.hash == hash;
}