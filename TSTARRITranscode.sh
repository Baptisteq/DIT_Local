#!/bin/bash

#---usage----#
usage(){
local ERROR=$1
echo "$0"
echo "ERROR: $ERROR"
exit
}

#--Set ARC_CMD.exe
ARRICMD="/cygdrive/c/Program Files/ARRI/ARC_CMD/GPU/x64/ARC_CMD.exe"
ARRIMetaExtract="/cygdrive/c/Program Files/ARRI/ARRI MetaExtract/ARRIMetaExtract_CMD.exe"
#--Set input parameters
ARRIMXF=$1
CONFIGXML=$2
OUTPUTFOLDER=$3
OUTPUTFILENAME=$4
STILLFRAME=$5

#---validation----#
# Does the ARC_CMD.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$ARRICMD" =~ .*/ARC_CMD.exe ]] && echo "$ARRICMD path correctly leads to the ARC_CMD.exe application" || usage "$ARRICMD access path doesn't lead to ARC_CMD.exe executable application".
  [[ -x $ARRICMD ]] && echo "ARC_CMD.exe application is correctly executable" || usage "$ARRICMD is not executable" 
  [[ "$ARRIMetaExtract" =~ .*/ARRIMetaExtract_CMD.exe ]] && echo "$ARRIMetaExtract path correctly leads to the ARRIMetaExtract_CMD.exe application" || usage "$ARRIMetaExtract access path doesn't lead to ARRIMetaExtract_CMD.exe executable application".
  [[ -x $ARRIMetaExtract ]] && echo "ARC_CMD.exe application is correctly executable" || usage "$ARRIMetaExtract is not executable"   
  exit
fi
#Does the ARRIRAW.mxf file a valid .MXF file
[[ "$ARRIMXF" =~ .*\.mxf ]] || usage "ARRIRAW file: $ARRIMXF is not a valid .mxf file."
[ -f $ARRIMXF ] || usage "ARRIRAW file: $ARRIMXF doesn't exist"

# DOes the config file a valid .XML file
[[ "$CONFIGXML" =~ .*\.xml ]] || usage "Config file: $CONFIGXML is not a valid .xml file."
[ -f $CONFIGXML ] || usage "Config file: $CONFIGXML doesn't exist"

# Does $OUTPUTFOLDER a valid dir ?
[ -d "$OUTPUTFOLDER" ] || usage "$OUTPUTFOLDER is not a valid dir"


#---WinPath transform----#
ARRIMXFWINPATH=$(echo "$ARRIMXF" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

#----ARRIRAW encoding -----#
# for each frame if DPX/EXR file already exists and it has the same size as the still media=> exit. If not=> encode.
SHOTFRAME=$( "$ARRIMetaExtract" --i $ARRIMXF| grep "Detected ARRIRAW frames:" | sed "s/[^0-9]//g")
# STILLSIZE=$(stat -c%s "$STILLDPX")

# predicts if the generated path is over 256 characters count. If so usage exit
# GENERATEDDPXPATTERNCOUNT=$(echo "$DPXSEQFOLDER""$RAWDPXFILENAME"".123456"".dpx" | wc -c)
# [ $GENERATEDDPXPATTERNCOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."
test condition
SHOTFRAME=5

for FRAME in $(seq 1 1 $SHOTFRAME)
do
  FRAMERANGE="-r $FRAME-$FRAME"
  FRAMENUMBER=$(printf "%06d\n" $FRAME)
  "$ARRICMD" -i $ARRIMXFWINPATH -c $CONFIGXML --output.directory $SEQFOLDER --output.filename "$OUTPUTFILENAME.$FRAMENUMBER" --cpu $FRAMERANGE
done
exit






