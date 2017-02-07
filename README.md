## Optical Flow Extraction for UCF101

This is the torch code, extracting optical flow of videos in UCF 101 dataset. This repo includes and uses [torch-ffmpeg](https://github.com/cvondrick/torch-ffmpeg) by Carl Vondrick for FFmpeg usage. Optical extraction part is largely based on the code: [VisionLabs/torch-opencv/demo/cuda/optical_flow.lua](https://github.com/VisionLabs/torch-opencv/blob/master/demo/cuda/optical_flow.lua). Optical flow will be saved as jpeg file, using first 2 channels to store the optical flow values.

### Requirements
1. install [cutorch](https://github.com/torch/cutorch) and [cv](https://github.com/VisionLabs/torch-opencv)
2. download [UCF101](http://crcv.ucf.edu/data/UCF101.php)


### Usage
Extract image frames from UCF101 videos.
```
th video2images.lua -dataset <path-to-UCF-101> -save <save directory>
```
Generate optical flows from the extracted video frames.
```
th img2optflow.lua -dataset <frame directory> -save <optical flow directory>
```
Sample Code.
```
th video2images.lua -dataset UCF/UCF-101 -save UCF/frames
th img2optflow.lua -dataset UCF/frames -save UCF/optflow
```
