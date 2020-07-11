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

# ffmpeg param
# framerate
FRAMERATE=$5
# ProRes codec (444,422HQ,422,422lt,Proxy)
PRESCODEC=$6
# Resize (SameAs,4K_DCI,UHD,2K_DCI,HD,HD720)
RESIZE=$7
# Lut3d filter (REC709, REC709_CDL, P3-DCI,P3-DCI_CDL,REC2100,REC2100_CDL)
LUT=$8

#----Input Validation-----#
# Does $INPUTIMGDIR is a valid dir ?
[ -d $INPUTIMGDIR ]  || usage "Input dir: $INPUTIMGDIR is not a valid dir."

# Does $EXTENSION a valid picture file extensions (.dpx .exr. tif .tiff .dng .png .jpeg .jpg .j2c .J2k)
[[ "$EXTENSION" =~ (dpx|exr|tif|tiff|dng|png|jpeg|jpg|j2c|j2k) ]] || usage "provided extensions: $EXTENSION is not a valid picture file extension."

# Does $INPUTIMGDIR contains picture files ?
PICTURESSEQUENCE=$(find $INPUTIMGDIR | grep "$EXTENSION")
[[ "$PICTURESSEQUENCE" == "" ]] && usage "Inputdir \"$INPUTIMGDIR\" doesn't contain any picture file"

# Do they all share the same base filename // Is there any missing frame trhoughout the sequence ?
BASEFILENAME=$(echo "$PICTURESSEQUENCE" | head -n 1 |  sed "s:^.*/\(.*\)\.[0-9]\+\+\+\+\+\."$EXTENSION"$:\1:")
NEXTFRAMENUMBER=$(echo "$PICTURESSEQUENCE" | head -n 1 | sed "s:^.*\([0-9][0-9][0-9][0-9][0-9][0-9]\)\."$EXTENSION"$:\1:")
for PICTURE in $PICTURESSEQUENCE
do
  [[ "$PICTURE" =~ "$BASEFILENAME" ]] || usage ".$EXTENSION picture file $PICTURE contained in INPUTDIR doesn't share the same filenaming ($BASEFILENAME)."
  FRAMENUMBER=$(echo "$PICTURE" | sed "s:^.*\([0-9][0-9][0-9][0-9][0-9][0-9]\)\."$EXTENSION"$:\1:")
  [ $FRAMENUMBER -eq $NEXTFRAMENUMBER ] || usage "$BASEFILENAME number $NEXTFRAMENUMBER is missing from the sequence. FFMPEG encode cannot be launched."
  ((NEXTFRAMENUMBER=FRAMENUMBER+1))
done

# Does the output dir a valid one ?
[ -d $OUTPUTDIR ] || usage "output dir:$OUTPUTDIR doesn't exist at this location"



#---------FFMPEG ENCODING-------------#
# Define PRORES CODEC (444,422HQ,422,422lt,Proxy)
case $PRESCODEC in
    "444")PRESPROFILE="-c:v prores_ks -profile:v 4 -pix-fmt yuv444p10";;
  "422HQ")PRESPROFILE="-c:v prores_ks -profile:v 3";;
    "422")PRESPROFILE="-c:v prores_ks -profile:v 2";;
  "422lt")PRESPROFILE="-c:v prores_ks -profile:v 1";;
  "Proxy")PRESPROFILE="-c:v prores_ks -profile:v 0";;
        *)PRESPROFILE="-c:v prores_ks -profile:v 3";;
esac

# Define Resize (SameAs,4K_DCI,UHD,2K_DCI,HD,HD720)
case $RESIZE in
    "SameAs")SCALE="";;
    "4K_DCI")SCALE="scale=4096:2160:force_original_aspect_ratio=decrease,pad=4086:2160:(ow-iw)/2:(oh-ih)/2";;
       "UHD")SCALE="scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2";;
    "2K_DCI")SCALE="scale=:2048:1080:force_original_aspect_ratio=decrease,pad=2048:1080:(ow-iw)/2:(oh-ih)/2";;
        "HD")SCALE="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2";;
     "HD720")SCALE="scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2";;
           *)SCALE="";;
esac

# Define Output Transform LUT
# File expression (REC709, REC709_CDL, P3-DCI,P3-DCI_CDL,REC2100,REC2100_CDL)
case $LUT in
      "REC709")LUTEXPR="REC-709-false.cube";;
  "REC709_CDL")LUTEXPR="REC-709-true.cube";;
      "P3-DCI")LUTEXPR="P3-DCI-false.cube";;
  "P3-DCI_CDL")LUTEXPR="P3-DCI-true.cube";;
     "REC2100")LUTEXPR="REC-2100-PQ-false.cube";;
 "REC2100_CDL")LUTEXPR="REC-2100-PQ-true.cube";;
             *)LUTEXPR="REC-709-false.cube";;
esac

LUTFILEWINPATH=$(find $OUTPUTDIR | grep "$LUTEXPR" | sed "s/cygdrive\/[a-z]\///"  )

# set ffmpeg input file sequence
SEQUENCEEXPR="$INPUTIMGDIR""/""$BASEFILENAME"".%06d"".""$EXTENSION"
SEQUENCEEXPRWINPATH=$(echo "$SEQUENCEEXPR" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

# Set output file full path and name plus .mov ext
OUTPUTFILE="$OUTPUTDIR""$FILENAME"".mov"
OUTPUTFILEWINPATH=$(echo "$OUTPUTFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

# Defined vf status (based on scale and LUT application
VFSTATUS=""
[[ "$SCALE" != "" ]] && VFSTATUS="-vf"
[[ "$FFMPEGLUT" != "" ]] && VFSTATUS="-vf" 

# predicts if the generated path is over 256 characters count. If so usage exit
OUTPUTFILECOUNT=$(echo "$OUTPUTFILEWINPATH" | wc -c)
[ $OUTPUTFILECOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

# FFMPEG encoding picture source to Apple ProRes (PRES422HQ) HD .mov
if [ -f $OUTPUTFILE ]; then
  echo $OUTPUTFILE
  else
  # echo "ffmpeg -f image2 -framerate \"$FRAMERATE\" -i \"$SEQUENCEEXPRWINPATH\" $PRESPROFILE $SCALE $FFMPEGLUT \"$OUTPUTFILEWINPATH\""
  ffmpeg -f image2 -framerate "$FRAMERATE" -i "$SEQUENCEEXPRWINPATH" $PRESPROFILE -vf "$SCALE,lut3d=$LUTFILEWINPATH" -sws_flags bicubic "$OUTPUTFILEWINPATH"
  echo $OUTPUTFILE
fi
