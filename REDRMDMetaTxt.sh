#!/bin/bash

#----Usage----#
# $1 needs to be a valid .R3D access path, $2 is OPT: it is either a valid path to an .RMD file, or a "None" string value, based on its value REDLine will either useMeta or useRMD 1
usage(){
local ERROR=$1
echo "$0, $1 needs to be a valid path to a .R3D file."
echo "$2 is opt. It eithers needs to be a valid path to a .RMD file or a string value set to None."
echo "$3 is the output dir where txt file is generated" 
exit
}

#----Input parameter----#
REDLINE="/cygdrive/c/Program Files/REDCINE-X PRO 64-bit/REDline.exe"
INPUTRED=$1
WINPATHINPUTRED=$( echo "$INPUTRED" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
INPUTRMD=$2
DPXSEQFOLDER=$3

#----Input Validation ----#
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] && echo "$REDLINE path correctly leads to the REDline.exe application" || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] && echo "REDline.exe application is correctly executable" || usage "$REDLINE is not executable"  
  exit
fi

[[ "$INPUTRED" =~ .*\.R3D ]] || usage "input file is not an .R3D file"
[ -d "$DPXSEQFOLDER" ] || usage "$DPXSEQFOLDER is not a valid dir"

#----set RMD status (either "--useMeta" or "--useRMD 1 " based in INPUTRMD value)
if [[ "$INPUTRMD" =~ .*\.RMD ]] && [ -f $RMDFILE ]; then
  RMDSTATUS="--useRMD 1 "
  elif [[ "$INPUTRMD" == "None" ]]; then 
  RMDSTATUS="--useMeta "
  else
  RMDSTATUS="--useMeta "
fi

#----OutPath//Filename-----#
OUTPUTPATH=$(echo "$DPXSEQFOLDER" | sed "s:\(.*\)/.*$:\1:" )
FILENAME=$(echo "$INPUTRED" | sed "s:.*/\(.*\)\.R3D:\1:" )
OUTPUTFILE="$OUTPUTPATH""/""$FILENAME""_REDMetadata.txt"

# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDFILECOUNT=$(echo "$OUTPUTFILE" | wc -c)
[ $GENERATEDFILECOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."

#----REDline print metadata to .txt file 
[ -f $OUTPUTFILE ] && rm $OUTPUTFILE
REDMETADATA=$("$REDLINE" --i $WINPATHINPUTRED $RMDSTATUS --printMeta 1)
echo "$REDMETADATA" >"$OUTPUTFILE"
echo $OUTPUTFILE