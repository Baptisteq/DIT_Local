#!/bin/bash

#---usage----#
usage(){
local ERROR=$1
echo "$0, $1 is a valid ARRIRAW.mxf file, $2 is a valid ARRI configuration file.xml, $3 is a valid dir for where files are generated,$4 is the base filename"
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
SHOTDURATION=$5
ACESSET=$6

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
[ -d "$OUTPUTFOLDER" ] || usage "$OUTPUTFOLDER is not a valid dir"

# Does SHOTDURATION a decimal ?
[[ "$SHOTDURATION" =~ [0-9]* ]] || usage "$SHOTDURATION is not an interger (it should be the shot duration expressed in number of frames"

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

#---calclul middle frame

((STILLFRAME=SHOTDURATION/2))

# specify frame range as the still frame
FRAMERANGE="-r $STILLFRAME-$STILLFRAME"

# specify framenumber to append to the final filename 
FRAMEPAD=$(printf "%06d\n" $STILLFRAME)

#----ARRIRAW encoding (Still Media)-----#
# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDDPXPATTERNCOUNT=$(echo "$OUTPUTFOLDER""$OUTPUTFILENAME"".123456.ext" | wc -c)
[ $GENERATEDDPXPATTERNCOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

[[ "$ACESSET" == "" ]] && EXTENSION="dpx"
[[ "$ACESSET" == "ACES" ]] && EXTENSION="exr"
GENERATEDFILE="$OUTPUTFOLDER""$OUTPUTFILENAME"".""$FRAMEPAD"".""$EXTENSION"

if [ -f $GENERATEDFILE ]; then
  echo "$GENERATEDFILE"
  else
  # encode still media
  "$ARRICMD" -i $ARRIMXFWINPATH -c $CONFIGXMLWINPATH --output.directory $OUTPUTFOLDER --output.filename "$OUTPUTFILENAME.$FRAMEPAD" --cpu $FRAMERANGE
  echo "$GENERATEDFILE"
fi

exit
