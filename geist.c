#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include "ljson/ljson.h"

const char* _lua_init =
    "require('boot')";

int main(int argc, char** argv) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    lua_newtable(L);
    lua_pushvalue(L, -1);
    lua_setglobal(L, "geist");
    luaopen_json(L);
    lua_setfield(L, -2, "json");
    lua_newtable(L);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i+1);
    }
    lua_setfield(L, -2, "args");
    luaL_dostring(L, "print('Lua OK')");
    if (luaL_dostring(L, _lua_init) != LUA_OK) {
        fprintf(stderr, "geist error: %s\n", lua_tostring(L, -1));
    }
    lua_close(L);
    return 0;
}
