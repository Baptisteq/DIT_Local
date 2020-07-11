#!/bin/bash

#---usage----#
usage(){

echo -e "$0
$ARRIMXF is a valid ARRIRAW.mxf file
$ARRIMETACSV is a valid ARRI configuration file.xml
$OUTPUTFOLDER is a valid dir for where files are generated
$OUTPUTFILENAME is the base filename
$STILL is the Still media used a reference (either .dpx or .exr)
$SHOTDURATION is the duration of the shot (expressed in number of frames)
$ACESSET is a string value to determine if either ACES2065 reversed mapping has to be applied or not (\"ACES\" or \"\")"
local ERROR=$1
echo "ERROR: $ERROR"
exit
}

#--Set ARC_CMD.exe
ARRICMD="/cygdrive/c/Program Files/ARRI/ARC_CMD/GPU/x64/ARC_CMD.exe"
ARRIMetaExtract="/cygdrive/c/Program Files/ARRI/ARRI MetaExtract/ARRIMetaExtract_CMD.exe"
#--Set input parameters
ARRIMXF=$1
ARRIMETACSV=$2
OUTPUTFOLDER=$3
OUTPUTFILENAME=$4
STILL=$5
SHOTDURATION=$6
ACESSET=$7


#---validation----#
# Does the ARC_CMD.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$ARRICMD" =~ .*/ARC_CMD.exe ]] && echo "$ARRICMD path correctly leads to the ARC_CMD.exe application" || usage "$ARRICMD access path doesn't lead to ARC_CMD.exe executable application".
  [[ -x $ARRICMD ]] && echo "ARC_CMD.exe application is correctly executable" || usage "$ARRICMD is not executable" 
  [[ "$ARRIMetaExtract" =~ .*/ARRIMetaExtract_CMD.exe ]] && echo "$ARRIMetaExtract path correctly leads to the ARRIMetaExtract_CMD.exe application" || usage "$ARRIMetaExtract access path doesn't lead to ARRIMetaExtract_CMD.exe executable application".
  [[ -x $ARRIMetaExtract ]] && echo "ARC_CMD.exe application is correctly executable" || usage "$ARRIMetaExtract is not executable"
  [ -f "/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCWideGamut.xml" ] || usage "ARRIDPX_LogCWideGamut.xml doesn't exit"
  [ -f "/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCCameraNative.xml" ] || usage "ARRIDPX_LogCCameraNative.xml doesn't exit"
  [ -f "/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCFilm.xml" ] || usage "ARRIDPX_LogCFilm.xml doesn't exit"
  
  exit
fi
#Does the ARRIRAW.mxf file a valid .MXF file
[[ "$ARRIMXF" =~ .*\.mxf ]] || usage "ARRIRAW file: $ARRIMXF is not a valid .mxf file."
[ -f $ARRIMXF ] || usage "ARRIRAW file: $ARRIMXF doesn't exist"

# Des the arri meta csv file a valid .csv file
[[ "$ARRIMETACSV" =~ .*\.csv ]] || usage "Arri meta CSV file: $ARRIMETACSV is not a valid .csv file."
[ -f $ARRIMETACSV ] || usage "Arri meta CSV file: $ARRIMETACSV doesn't exist"

# Does $OUTPUTFOLDER a valid dir ?
[ -d "$OUTPUTFOLDER" ] || usage "output folder:$OUTPUTFOLDER is not a valid dir"

# STILL DPX is a valid .dpx file, it has to be a valid DPX file based on which the sequence folder will be encoded following excactly the same technical specifications
[[ "$STILL" =~ .*\.dpx ]] || [[ "$STILL" =~ .*\.exr ]] || usage "still media: $STILL is not a valid .dpx file or a valid .exr file"
[ -f $STILL ] || usage "$STILL has not been found"

# Does SHOTDURATION a decimal ?
[[ "$SHOTDURATION" =~ [0-9]* ]] || usage "shot frame count: $SHOTDURATION is not an interger (it should be the shot duration expressed in number of frames"

#---WinPath transform----#
ARRIMXFWINPATH=$(echo "$ARRIMXF" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
OUTPUTFOLDERWINPATH=$(echo "$OUTPUTFOLDER" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

#---extract target color space information----#
TARGETCOLORSPACE=$(./ARRIFileNaming.sh $ARRIMETACSV ":Target Color Space")

#Based on target Color space value, decide what config file to use. Path has to be refered by user on every machine.
#Based on if ACES pipeline is set. 
if [ "$ACESSET" = "" ]; then
  case $TARGETCOLORSPACE in
    "LogCWGam")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCWideGamut.xml";;
    "LogCCamN")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCCameraNative.xml";;
    "LogCFilm")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCFilm.xml";;
           "*")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIDPX_LogCWideGamut.xml";;
  esac
elif [ "$ACESSET" = "ACES" ]; then
  case $TARGETCOLORSPACE in
      "LogCWGam")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIEXR_ACES-SceneLinear-WideGamut.xml";;
      "LogCCamN")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIEXR_ACES-SceneLinear-CameraNative.xml";;
      "LogCFilm")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIEXR_ACES-SceneLinear-WideGamut.xml";;
             "*")CONFIGXML="/cygdrive/c/Users/alice/Desktop/TEST_BATCH/BASH/TEST_DIT/ARRI_ConfigXML/ARRIEXR_ACES-SceneLinear-WideGamut.xml";;
  esac
fi
CONFIGXMLWINPATH=$(echo "$CONFIGXML" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


#----ARRIRAW encoding (Still Media)-----#
# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDDPXPATTERNCOUNT=$(echo "$OUTPUTFOLDER""$OUTPUTFILENAME"".123456"".ext" | wc -c)
[ $GENERATEDDPXPATTERNCOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

#---Get Still media size (it will be used for reference purpose to check if each generated dpx share the exact same size)
STILLSIZE=$(stat -c%s "$STILL")

[[ "$ACESSET" == "" ]] && EXTENSION="dpx"
[[ "$ACESSET" == "ACES" ]] && EXTENSION="exr"

#test condition
SHOTDURATION=5
for FRAME in $(seq 1 1 $SHOTDURATION)
do
  PADFRAME=$(printf "%06d\n" $FRAME)
  FRAMEFILENAME="$OUTPUTFILENAME"".""$PADFRAME"
  GENERATEDDPX="$OUTPUTFOLDER""/""$FRAMEFILENAME"".""$EXTENSION"
  if [ -f $GENERATEDDPX ] && [ $(stat -c%s $GENERATEDDPX) == "$STILLSIZE" ]; then
  PICTUREFILE="$GENERATEDDPX"
  echo "$PICTUREFILE already exists no render achieved"
  else
  # ARC_CMD will encode source picture in DPX. Preserving its native color space (LogCWG, LogCCamNative, LogCFilm).
  FRAMERANGE="-r $FRAME-$FRAME"
  PICTUREFILE=$("$ARRICMD" -i $ARRIMXFWINPATH -c $CONFIGXMLWINPATH --output.directory $OUTPUTFOLDER --output.filename $FRAMEFILENAME --cpu $FRAMERANGE)
  echo "$PICTUREFILE"
  fi
done
exit
