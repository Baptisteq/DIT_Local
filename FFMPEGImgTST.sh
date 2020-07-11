#!/bin/bash
# set -x
#----usage----#
usage(){
echo "$0
\"$INPUTIMGDIR\" is a valid input dir that contains picture files (dpx/exr...) Identified by a 6 digit pad numbering at suffix (input_file_%06d.ext)
\"$EXTENSION\" is a valid picture file extensions as follow:(dpx|exr|tif|tiff|dng|png|jpeg|jpg|j2c|J2k).
"
local ERROR=$1
echo "ERROR:$ERROR"
exit
}

#---Input Parameter---#

INPUTIMGDIR=$1
EXTENSION=$2
OUTPUTDIR=$3
FILENAME=$4
# Lut3d filter
LUT=$5

# Define Output Transform LUT
LUTWINPATH=$(echo "$LUT" |  sed "s/cygdrive\/[a-z]\///" )
echo $LUTWINPATH



# set ffmpeg input file sequence
PICTURESSEQUENCE=$(find $INPUTIMGDIR | grep "$EXTENSION")
BASEFILENAME=$(echo "$PICTURESSEQUENCE" | head -n 1 |  sed "s:^.*/\(.*\)\.[0-9]\+\+\+\+\+\."$EXTENSION"$:\1:")
SEQUENCEEXPR="$INPUTIMGDIR""/""$BASEFILENAME"".%06d"".""$EXTENSION"
SEQUENCEEXPRWINPATH=$(echo "$SEQUENCEEXPR" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

# Set output file full path and name plus .mov ext
OUTPUTFILE="$OUTPUTDIR""/""$FILENAME"".mov"
OUTPUTFILEWINPATH=$(echo "$OUTPUTFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


ffmpeg -f image2 -framerate "24" -i "$SEQUENCEEXPRWINPATH" -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,lut3d=$LUTWINPATH" -sws_flags bicubic $OUTPUTFILEWINPATH
# ffmpeg -f image2 -framerate "23.976" -i "$SEQUENCEEXPRWINPATH" -c:v prores_ks -profile:v 3 $SCALE $FFMPEGLUT "$OUTPUTFILEWINPATH"



