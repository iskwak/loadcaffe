local ffi = require 'ffi'
local C = loadcaffe.C


-- given a caffe datum byte array, this function will return the image
-- and its metadata
-- At the moment it cannot handle encoded images (datum.encoded == true)
loadcaffe.parseCaffeDatum = function(byteArray)

    local img = torch.FloatTensor()
    local label = torch.FloatTensor(1)

    C.parseCaffeDatumEntry( byteArray:cdata(), img:cdata(), label:cdata())

    return img,label
end


loadcaffe.load = function(prototxt_name, binary_name, backend)
  local backend = backend or 'nn'
  local handle = ffi.new('void*[1]')

  -- loads caffe model in memory and keeps handle to it in ffi
  local old_val = handle[1]
  C.loadBinary(handle, prototxt_name, binary_name)
  if old_val == handle[1] then return end

  -- transforms caffe prototxt to torch lua file model description and 
  -- writes to a script file
  local lua_name = prototxt_name..'.lua'
  C.convertProtoToLua(handle, lua_name, backend)

  -- executes the script, defining global 'model' module list
  local model = dofile(lua_name)

  -- goes over the list, copying weights from caffe blobs to torch tensor
  local net = nn.Sequential()
  local list_modules = model
  for i,item in ipairs(list_modules) do
    if item[2].weight then
      local w = torch.FloatTensor()
      local bias = torch.FloatTensor()
      local gw = torch.FloatTensor()
      local gbias = torch.FloatTensor()
      C.loadModule(handle, item[1], w:cdata(), bias:cdata(),
          gw:cdata(), gbias:cdata())
      if backend == 'ccn2' then
        w = w:permute(2,3,4,1)
      end
      item[2].weight:copy(w)
      item[2].bias:copy(bias)
      if gw:size():size() > 0 then
        item[2].gradWeight:copy(gw)
        item[2].gradBias:copy(gbias)
      end
    end
    net:add(item[2])
  end
  C.destroyBinary(handle)

  if backend == 'cudnn' or backend == 'ccn2' then
    net:cuda()
  end

  return net
end
