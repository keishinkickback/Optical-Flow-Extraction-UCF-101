require 'paths'
require 'torch-ffmpeg'
require 'image'

local M = {}

-- given top directory of original UCF101
--> return all video file names
function M.getFileNames(dir_og)
  local tblDirs = {}
  local tblFiles = {}
  for dir in paths.iterdirs(dir_og) do
    table.insert(tblDirs, dir)
  end
  table.sort(tblDirs)
  for i=1, #tblDirs do
    local dir_temp = paths.concat(dir_og,tblDirs[i])
    for f in paths.iterfiles(dir_temp) do
      table.insert(tblFiles, paths.concat(dir_temp, f))
    end
  end
  return tblFiles
end

-- given top directory of original UCF101
--> return all video file names
function M.getDirNames(dir_og)
  local tblDirs = {}
  for dir in paths.iterdirs(dir_og) do
    local dir2 = paths.concat(dir_og, dir)
    for dir3 in paths.iterdirs(dir2) do
      table.insert(tblDirs, paths.concat(dir2, dir3))
    end
  end
  table.sort(tblDirs)
  return tblDirs
end

-- given file name
--> return a table of frames of a video
function M.videoToTensor(videoPath, argFFmpeg)
  argFFmpeg = argFFmpeg or '-s 320x240'
  local vid = FFmpeg(videoPath, argFFmpeg)
  local frames ={}
  while true do
	  local t = vid:read(1) --> vid:read() return byte tensor and scaled 0-255!
    if t == nil then break
    else
      table.insert(frames, t:reshape(3,240,320):float() / 255)
    end
  end
  vid:close()
  return frames
end

-- given a video File name, and a table of frames
--> save all frames as a series of jpg files
function M.saveImages(name,tblImages)
  for i = 1, #tblImages do
    if not paths.filep(paths.concat(name, tostring(i)..'.jpg') ) then
      image.save(name .. '/'.. tostring(i) .. '.jpg', tblImages[i])
    end
  end
end

-- given save directory and video file name
--> create a directory if it does not exist
function M.checkCreateDir(dir_save, name)
  if not paths.dirp(paths.concat(dir_save, name)) then
    paths.mkdir(paths.concat(dir_save, name))
  end
end

-- check there is any jpg files
--> return if the file exists or not (boolean)
function M.checkIfFiles(dir_save, name, index)
  index = index or 1
  return paths.filep(paths.concat(dir_save, name, tostring(index)..'.jpg'))
end

-- given video paths
--> return label (ex. Archery) and name (ex. v_Archery_g12_c02 )
function M.getVideoNames(videoPath)
  local name, _ =videoPath:match("([^.]+).([^.]+)")
  _, name = name:match('(.+)/([^/]+)')
  local label
  _, label = _:match('(.+)/([^/]+)')
  return label, name
end

function M.getLableVideoNames(videoPath)
  local pre, label, name =videoPath:match("([^.]+)/([^/]+)/([^/]+)")
  return label, name
end

function M.getFileCount(dir)
  local count = 0
  for f in paths.iterfiles(dir) do
    count = count + 1
  end
  return count
end

return M
