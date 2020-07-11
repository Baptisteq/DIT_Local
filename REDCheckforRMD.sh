#!/bin/bash

#----usage-----#
#$1 needs to be a valid path to a given .R3D file. Script will then seek for a .RMD file in same current direcorty of the R3D file. 
# Script will return .RMD absolute cygwin path.

usage (){
echo "$0, $1 needs to be a valid path leading to a .R3D file."
echo "$2 is optionnal dir path leading to all RMD files where potentially attached RMD file to the input .R3D clip is stored in"
exit
}

#---REDLINE set & validation ----#
REDLINE="C:/Program Files/REDCINE-X PRO 64-bit/REDline.exe"
if [[ "$1" == "Init" ]]; then
  [[ "$REDLINE" =~ .*/REDline.exe ]] || usage "$REDLINE access path doesn't lead to REDline.exe executable application".
  [[ -x $REDLINE ]] || usage "$REDLINE is not executable"  
  exit
fi
#---input parameter---#
INPUTREDFILE=$1
OPTIONNALRMDMASTERDIR=$2
INPUTREDFILEWINPATH=$(echo "$INPUTREDFILE" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null  )

#----input validation----#
[[ "$INPUTREDFILE" =~ .*\.R3D ]] || usage "input file is not an .R3D file"
[ -d "$OPTIONNALRMDMASTERDIR" ]
#----Current directory where .R3D file is given access to ----#
REDFILECURRENTDIR=$(echo "$INPUTREDFILE" | sed "s:\(.*\)/.*$:\1:" )

#----.R3D ClipName----#
REDCLIPNAME=$("$REDLINE" --silent --i $INPUTREDFILEWINPATH --printMeta 1 | grep "^Clip Name" | tr -d "[:blank:]" | sed "s/.*:\(.*\)/\1/" | tr -d "\r" )

#----search for .RMD file sharing the sameclipname in current directory, if no RMD file exists in this current dir. Set not value to RMDFILE ---#
RMDFILE="$REDFILECURRENTDIR""/""$REDCLIPNAME"".RMD"

#----if RMDfile set to NULL, search RMD file based on optionnal master RMD dir----#
[ -f $RMDFILE ] || RMDFILE="$OPTIONNALRMDMASTERDIR""/""$REDCLIPNAME"".RMD"
[ -f $RMDFILE ] || echo "None"
echo "$RMDFILE"
#---end---#
exit

 