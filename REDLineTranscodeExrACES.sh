#!/bin/bash
# set -x
#---Usage----#
usage (){
local ERROR="$1"
echo "$0, $REDLINE needs to be set correctly (cygdrive Syntax ex: \"/cygdrive/c/Program Files/REDCINE-X PRO 64-bit/REDline.exe\""
echo "ERROR: $ERROR" 
exit
}




#----Input Statement ----#

REDLINE="/cygdrive/c/Program Files/REDCINE-X PRO 64-bit/REDline.exe"
RAWREDFILE=$1
EXRSEQFOLDER=$2
RAWEXRFILENAME=$3

# converting unix cygwin path to win path
WINPATHRAWREDFILE=$(echo "$RAWREDFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
WINPATHEXRSEQFOLDER=$(echo "$EXRSEQFOLDER" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


#---validation----#
# Does the REDLine.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] && echo "$REDLINE path correctly leads to the REDline.exe application" || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] && echo "REDline.exe application is correctly executable" || usage "$REDLINE is not executable"  
  exit
fi
# Does $RAWREDFILE a valid .R3D file ?
[[ "$RAWREDFILE" =~ .*\.R3D ]] || usage "RAWREDFILE: $RAWREDFILE is not a valid .R3D file.".
# Does $EXRSEQFOLDER a valid dir ?
[ -d "$EXRSEQFOLDER" ] || usage "$EXRSEQFOLDER is not a valid dir"

#---REDline encode ----#
# for each frame if DPX file already exists and it has the same size as the still media=> exit. If not=> encode.
SHOTFRAME=$( "$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --printMeta 1 | grep "Total Frames" | sed "s/[^0-9]//g")
# STILLSIZE=$(stat -c%s "$STILLDPX")
# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDEXRPATTERNCOUNT=$(echo "$EXRSEQFOLDER""$RAWEXRFILENAME"".123456"".exr" | wc -c)
[ $GENERATEDEXRPATTERNCOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."
#test condition
SHOTFRAME=5
for FRAME in $(seq 1 1 $SHOTFRAME)
do

# REDLine will encode source picture in openEXR. reversing camera gamma and color curve to ACES2065-1 wild gamut and lin16 float)
"$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --start $FRAME --end $FRAME --format 2 --exrACES 1  --gpuPlatform 0 --noAudio --NR 0 --rollOff 0  --outDir $WINPATHEXRSEQFOLDER --o "$RAWEXRFILENAME.$FRAME.exr"

done
exit
