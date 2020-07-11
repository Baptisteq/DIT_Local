#!/bin/bash
# set -x
#---Usage----#
usage (){
local ERROR="$1"
echo "$0, $REDLINE needs to be set correctly (cygdrive Syntax ex: \"/cygdrive/c/Program Files/REDCINE-X PRO 64-bit/REDline.exe\""
echo "$0 RAWREDFILE PROXYFILENAME PRCODEC COLORSCIENCE ROLLOFF OUTPUTTONEMAP GAMMACURVE COLORSPACE"
echo "ERROR: $ERROR" 
exit
}

#----Input Statement ----#

REDLINE="/cygdrive/c/Program Files/REDCINE-X PRO 64-bit/REDline.exe"
RAWREDFILE=$1
PROXYFILENAME=$2
PRCODEC=$3
COLORSCIENCE=$4
ROLLOFF=$5
OUTPUTTONEMAP=$6
GAMMACURVE=$7
COLORSPACE=$8
RESIZE=$9
BURNEDIN="${10}"
WTMK="${11}"

# converting unix cygwin path to win path
WINPATHRAWREDFILE=$(echo "$RAWREDFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
WINPATHPROXYFILENAME=$(echo "$PROXYFILENAME" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )


#---validation----#
# Does the REDLine.exe's access path is correctly provided ?
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] && echo "$REDLINE path correctly leads to the REDline.exe application" || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] && echo "REDline.exe application is correctly executable" || usage "$REDLINE is not executable"  
  exit
fi
# Does $RAWREDFILE a valid .R3D file ?
[[ "$RAWREDFILE" =~ .*\.R3D ]] || usage "RAWREDFILE: $RAWREDFILE is not a valid .R3D file.".
# Does $PROXYFILENAME is a valid .mov filename ?

# Does $PRCODEC correctly defined ?
[[ $PRCODEC =~ [^0-5] ]] && PRCODEC=0 && echo "PRCODEC: $3 not clearly set (0-4). ProRes codec is set to 0.ProRes 422HQ.
0.Apple ProRes 422 HQ
1.Apple ProRes 422 
2.Apple ProRes 422 LT
3.Apple ProRes 422 Proxy
4.Apple ProRes 4444 
5.Apple ProRes 4444 XQ"
 
# Does $COLORSCIENCE correctly defined ?
[[ $COLORSCIENCE =~ [^0-3] ]] && COLORSCIENCE=3 && echo -e "ColorScience value: $COLORSCIENCE is not an int value. By defaut set to 3:
--colorSciVersion <int>:
0. Current Version 
1.Version1
2.FLUT
3.IPP2
NOTE:Current Version is used if the clip was created with a MYSTERIUM-X sensor or later."

# Does $ROLLOFF Correctly defined
[[ $ROLLOFF =~ [^0-4] ]] && ROLLOFF=2 && echo -e "RollOff value: $COLORSCIENCE is not clearly defined. By defaut set to 2: Default
0. None
1. Hard
2. Default
3. Medium
4. Soft"

# Does $OUTPUTTONEMAP correctly defined 
[[ $OUTPUTTONEMAP =~ [^0-3] ]] && OUTPUTTONEMAP=3 && echo -e "OutputToneMap value: $OUTPUTTONEMAP is not clearly defined. By defaut set to 3: None
0. Low
1. Medium
2. High
3. None"

# Does GAMMACURVE Correctly defined
[[ $GAMMACURVE =~ (-)?[^0-9][^0-9] ]] && GAMMACURVE=32 && echo -e "GammaCurve  value: $GAMMACURVE is not clearly defined. By defaut set to 32: BT.1886
-1 = lin
1 = rec709
2 = sRGB
3 = REDlog
4 = PDLog985
5 = PDLog685
6 = PDLogCustom
14 = REDspace
15 = REDgamma
27 = REDLogFilm
28 = REDgamma2
29 = REDgamma3
30 = REDgamma4
31 = HDR-2084
32 = BT1886
33 = Log3G12
34 = Log3G10"

# Does COLORSPACE Correctly defined
[[ $COLORSPACE =~ [^0-9][^0-9] ]] && COLORSPACE=1 && echo -e "Color space value: $COLORSPACE is not clearly defined. By defaut set to 1: REC709
2 or 11 = REDspace
0 or 12 = CameraRGB
1 or 13 = rec709
14 = REDcolor
15 = sRGB
5 = Adobe1998
18 = REDcolor2
19 = REDcolor3
20 = DRAGONcolor
21 = XYZ
22 = REDcolor4
23 = DRAGONcolor2
24 = rec2020
25 = REDWideGamutRGB"

# Does Resize correctly defined
[ "$RESIZE" != "1080" ] && [ "$RESIZE" != "720" ] && RESIZE="1080" && echo "Resize value needs to be either 1080 or 720. When 1080 is set. A 1920x1080 resize is applied while preserving OAR. 
When 720 is set. A 1280x720 resize is applied while preserving OAR.
By default. A 1920x1080 resize has been applied."

# RESIZE PROCESS #
[ "$RESIZE" == "1080" ] && SETSIZE="--resizeX 1920 --resizeY 1080"
[ "$RESIZE" == "720" ] && SETSIZE="--resizeX 1280 --resizeY 720"

# BURNED IN PROCESS #
[[ $BURNEDIN != 0 ]] && SETBURNEDIN="--burnIn --burnUL 1 --burnLL 6 --burnLR 4"
# WATERMARK PROCESS #
[ "$WTMK" == "" ] || SETWTMK="--watermark --watermarkText \"$WTMK\" --watermarkFont 'Courier' --watermarkSz 2 --watermarkTxtA 0.4 " 

#---REDline encode ----#
# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDFILECOUNT=$(echo "$PROXYFILENAME"".mov" | wc -c)
[ $GENERATEDFILECOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

GENERATEDFILE="$PROXYFILENAME"".mov"
if [ -f $GENERATEDFILE ]; then
  echo $GENERATEDFILE
  else
# REDLine will encode source picture in DPX. reversing camera gamma and color curve to primary development standard (RWG//Log3G10)
"$REDLINE" --i $WINPATHRAWREDFILE --o $WINPATHPROXYFILENAME --useRMD 1 --start 0 --end 5 --format 201 --PRcodec $PRCODEC --gpuPlatform 0 --colorSciVersion $COLORSCIENCE --NR 0 --rollOff $ROLLOFF --outputToneMap $OUTPUTTONEMAP --gammaCurve $GAMMACURVE --colorSpace $COLORSPACE $SETSIZE $SETBURNEDIN $SETWTMK
fi

exit
