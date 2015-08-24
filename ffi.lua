local ffi = require 'ffi'

ffi.cdef[[
void loadBinary(void** handle, const char* prototxt_name, const char* binary_name);
void destroyBinary(void** handle);
void convertProtoToLua(void** handle, const char* lua_name, const char* cuda_package);
void loadModule(void** handle, const char* name, THFloatTensor* weight, THFloatTensor* bias, THFloatTensor* gradWeight, THFloatTensor* gradBias);
void parseCaffeLmdbDatumEntry(THByteTensor* datum, THFloatTensor* img, THFloatTensor* label);
]]

loadcaffe.C = ffi.load(package.searchpath('libloadcaffe', package.cpath))
