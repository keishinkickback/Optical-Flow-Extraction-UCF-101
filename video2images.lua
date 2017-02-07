require 'paths'
require 'xlua'
local M = require 'utils'

local cmd = torch.CmdLine()
cmd:text()
cmd:option('-dataset',          "",            'set UCF-101 video image folder')
cmd:option('-save',             "",            'where to save images')
cmd:option('-start',             1,            'starting index')
cmd:option('-ending',              -1,            'end index')
cmd:option('-nThreads',          1,            'set number of threads (openMp)')
cmd:option('-argFFmpeg',        '-s 320x240',  'argument for FFmpeg')
cmd:text()

local opt = cmd:parse(arg)

if not paths.dirp(opt.dataset) then
  cmd:error('error: missing UCF-101 data directory')
end
if not paths.dirp(opt.save) then
  cmd:error('error: missing save directory')
end

-- target directorie
dir_target = opt.dataset
dir_save = opt.save

-- get all file names
fileNames = M.getFileNames(dir_target)

if opt.ending == -1 then opt.ending = #fileNames end
local goal = opt.ending - opt.start + 1

for i= opt.start, opt.ending do
  local label, videoName = M.getVideoNames(fileNames[i]) --> get label and video names
  M.checkCreateDir(dir_save, label .. '/' .. videoName) --> create directory
  local frames = M.videoToTensor(fileNames[i]) -- > get frames
  M.saveImages(paths.concat(dir_save, label, videoName), frames) --> save as pix
  xlua.progress(i, goal)
end
