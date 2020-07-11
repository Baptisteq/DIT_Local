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

# converting unix cygwin path to win path
WINPATHRAWREDFILE=$(echo "$RAWREDFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


#---validation----#
# Does the REDLine.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] && echo "$REDLINE path correctly leads to the REDline.exe application" || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] && echo "REDline.exe application is correctly executable" || usage "$REDLINE is not executable"  
  exit
fi
# Does $DPXSEQFOLDER a valid dir ?
[ -d "$DPXSEQFOLDER" ] || usage "$DPXSEQFOLDER is not a valid dir"
# Does $RAWREDFILE a valid .R3D file ?
[[ "$RAWREDFILE" =~ .*\.R3D ]] || usage "RAWREDFILE: $RAWREDFILE is not a valid .R3D file.".
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

#---RedLine extract framenumber information and determine half media frame number---#
SHOTFRAMELENGH=$("$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --printMeta 1 | grep "Total Frames:" | tr -d "[:blank:]" | sed "s/.*:\([0-9]*\)/\1/" | tr -d "\r" )
((MIDDLEFRAME=SHOTFRAMELENGH/2))

#---Still Filename // Still path(Win path syntax)----#
RAWDPXSTILLFILENAME="$RAWDPXFILENAME""_STILL"
RAWDPXSTILLPATH=$(echo "$DPXSEQFOLDER" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

#---REDline encode ----#
# check if anticipated still dpx file already exists. Exit script without render if so
NOMIDDLEFRAME=$(printf "%06d\n" $MIDDLEFRAME)
GENERATEDFILE="$DPXSEQFOLDER""$RAWDPXSTILLFILENAME"".""$NOMIDDLEFRAME"".dpx"
#---REDline encode ----#
# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDFILECOUNT=$(echo "$GENERATEDFILE" | wc -c)
[ $GENERATEDFILECOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

if [ -f $GENERATEDFILE ]; then
  echo $GENERATEDFILE
  else
  # REDLine will encode source picture in a still DPX. reversing camera gamma and color curve to primary development standard (RWG//Log3G10)
  "$REDLINE" --i $WINPATHRAWREDFILE --useRMD 1 --start $MIDDLEFRAME  --end $MIDDLEFRAME --format 0 --bitDepth $BITDEPTH --gpuPlatform 0 --noAudio --colorSciVersion $COLORSCIENCE --primaryDev --NR 0 --rollOff 0  --outDir $RAWDPXSTILLPATH --o $RAWDPXSTILLFILENAME
  echo $GENERATEDFILE
fi

exit
