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
DPXSEQFOLDER=$2
RAWDPXFILENAME=$3
BITDEPTH=$4
COLORSCIENCE=$5
STILLDPX=$6

# converting unix cygwin path to win path
WINPATHRAWREDFILE=$(echo "$RAWREDFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
WINPATHDPXSEQFOLDER=$(echo "$DPXSEQFOLDER" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


#---validation----#
# Does the REDLine.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] && echo "$REDLINE path correctly leads to the REDline.exe application" || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] && echo "REDline.exe application is correctly executable" || usage "$REDLINE is not executable"  
  exit
fi
# Does $RAWREDFILE a valid .R3D file ?
[[ "$RAWREDFILE" =~ .*\.R3D ]] || usage "RAWREDFILE: $RAWREDFILE is not a valid .R3D file.".
# Does $DPXSEQFOLDER a valid dir ?
[ -d "$DPXSEQFOLDER" ] || usage "$DPXSEQFOLDER is not a valid dir"
# Does $BITDEPTH correctly defined ?
[ $BITDEPTH != 10 ] && [ $BITDEPTH != 16 ] && BITDEPTH=16 && echo "BITDEPTH: $4 not clearly set (10 or 16). DPX BitDepth set to 16 by def."
# Does $COLORSCIENCE correctly defined ?
[[ $COLORSCIENCE =~ [^0-3] ]] && COLORSCIENCE=3 && echo -e "ColorScience value: $COLORSCIENCE is not an int value. By defaut set to 3:
--colorSciVersion <int>:
0. Current Version 
1.Version1
2.FLUT
3.IPP2
NOTE:Current Version is used if the clip was created with a MYSTERIUM-X sensor or later."
# STILL DPX is a valid .dpx file, it has to be a valid DPX file based on which the sequence folder will be encoded following excactly the same technical specifications
[[ "$STILLDPX" =~ .*\dpx ]] && [ -f $STILLDPX ] || usage "$STILLDPX is not a valid .dpx file"
#---REDline encode ----#
# for each frame if DPX file already exists and it has the same size as the still media=> exit. If not=> encode.
SHOTFRAME=$( "$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --printMeta 1 | grep "Total Frames" | sed "s/[^0-9]//g")
STILLSIZE=$(stat -c%s "$STILLDPX")

# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDDPXPATTERNCOUNT=$(echo "$DPXSEQFOLDER""$RAWDPXFILENAME"".123456"".dpx" | wc -c)
[ $GENERATEDDPXPATTERNCOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."
#test condition
SHOTFRAME=5
for FRAME in $(seq 1 1 $SHOTFRAME)
do
  PADFRAME=$(printf "%06d\n" $FRAME)
  GENERATEDDPX="$DPXSEQFOLDER""$RAWDPXFILENAME"".""$PADFRAME"".dpx"
  if [ -f $GENERATEDDPX ] && [ $(stat -c%s $GENERATEDDPX) == "$STILLSIZE" ]; then
  echo "$GENERATEDDPX already exists it appears that it has exactly the same size as the still sample media $STILLSIZE . No render achieved."
  else
  # REDLine will encode source picture in DPX. reversing camera gamma and color curve to primary development standard (RWG//Log3G10)
  "$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --start $FRAME --end $FRAME --format 0 --bitDepth $BITDEPTH --gpuPlatform 0 --noAudio --colorSciVersion $COLORSCIENCE --primaryDev --NR 0 --rollOff 0  --outDir $WINPATHDPXSEQFOLDER --o $RAWDPXFILENAME
  fi
done
exit
