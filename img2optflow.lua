require 'paths'
require 'image'
require 'math'
require 'xlua'
local M = require 'utils'

require 'cutorch'
local cv = require 'cv'
require 'cv.cudaoptflow'
require 'cv.imgcodecs'
require 'cv.imgproc'
require 'cv.highgui'

--------------------------------------------------------------------------------
-- OPTICAL flow
--------------------------------------------------------------------------------
function alignUp(x, alignBoundary)
    alignBoundary = alignBoundary or 512
    local rowBytes = x:size(x:dim()) * x :elementSize()
    local strideBytes = math.ceil(rowBytes/alignBoundary)*alignBoundary
    return strideBytes/x:elementSize()
end

function _optCompute(dir_save, fileName, index)
-- load images and copy into memory-aligned CudaTensor
  cpuImages={}
  gpuImages={}
  for i=1, 2 do
    local vName = paths.concat(fileName, tostring(index + i - 1) .. '.jpg')
    cpuImages[i] = cv.imread{vName, cv.IMREAD_GRAYSCALE}
    assert(cpuImages[i]:nDimension() > 0, 'Could not load ')
    cpuImages[i]=cpuImages[i]:float():div(255)
    local sizes=cpuImages[i]:size()
    local strides=torch.LongStorage{alignUp(cpuImages[i]), -1}
    gpuImages[i]=torch.CudaTensor(sizes, strides)
    gpuImages[i]:copy(cpuImages[i])
  end
  -- perform optical flow calculation
  optflow = cv.cuda.BroxOpticalFlow{}
  local flow = optflow:calc{I0=gpuImages[1], I1=gpuImages[2]}:cuda():float():clone()
  return flow:transpose(1,3):transpose(2,3)
end

function optCompute(dir_save, fileName)
  local count = M.getFileCount(fileName)
  optFlow = torch.FloatTensor(3,240, 320):zero()
  for i = 1, count - 1 do
    local label, name = M.getLableVideoNames(fileName)
    if not M.checkIfFiles(dir_save, label ..'/'..name, i) then
      optFlow:zero()
      optFlow[{{1,2},{},{}}] = _optCompute(dir_save, fileName, i)
      image.save(paths.concat(dir_save,label,name, tostring(i) .. '.jpg'),optFlow:clone())
    end
  end
end


local cmd = torch.CmdLine()
cmd:option('-dataset',     '',           'set UCF-101 video image folder')
cmd:option('-save',        '',           'where to save optical flow')
cmd:option('-start',        1,           'starting index')
cmd:option('-ending',         -1,           'ending index')
cmd:option('-gpu',          1,           'set GPU device')
cmd:option('-nThreads',     1,           'set number of threads (openMp)')

cmd:text()

local opt = cmd:parse(arg)

if not paths.dirp(opt.dataset) then
  cmd:error('error: missing UCF-101 video image directory')
end
if not paths.dirp(opt.save) then
  cmd:error('error: missing save directory')
end


dir_target =  opt.dataset
dir_save =  opt.save

tbl = M.getDirNames(dir_target)

if opt.ending == -1 then
  opt.ending = #tbl
end

torch.setnumthreads(opt.nThreads)
cutorch.setDevice(opt.gpu)

local goal = opt.ending - opt.start + 1
print(#tbl)

for i=opt.start, opt.ending do
  local videopath = tbl[i]
  local label, name = M.getLableVideoNames(videopath)
  M.checkCreateDir(dir_save, label .. '/' .. name )
  optCompute(dir_save, videopath)
  xlua.progress(i-opt.start + 1, goal)
end
