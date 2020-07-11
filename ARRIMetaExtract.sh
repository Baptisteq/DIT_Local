#!/bin/bash
#----Usage----#
# $1 needs to be a valid ARRIRAW.mxf access path
usage(){
echo "$0, $1 needs to be a valid path to a ARRIRAW.mxf file."
echo "$2 is the output dir where txt file is generated" 
local ERROR=$1
echo "ERROR:$ERROR"
exit
}

#-- store default IFS value
OLDIFS=$IFS

ARRIMetaExt="/cygdrive/c/Program Files/ARRI/ARRI MetaExtract/ARRIMetaExtract_CMD.exe"

INPUTMXF=$1
OUTPUTPATH=$2
FILENAME=$(echo "$INPUTMXF" | sed "s:.*/\(.*\).mxf:\1:")
OUTPUTDIR="$OUTPUTPATH""$FILENAME""_METADATA"

#----Input Validation ----#
if [[ "$1" == "Init" ]]; then
  [[ "$ARRIMetaExt" =~ .*/ARRIMetaExtract_CMD.exe ]] && echo "$ARRIMetaExt path correctly leads to the ARRIMetaExtract_CMD.exe application" || usage "$ARRIMetaExt access path doesn't lead to ARRIMetaExtract_CMD.exe executable application".
  [[ -x $ARRIMetaExt ]] && echo "ARRIMetaExtract_CMD.exe application is correctly executable" || usage "$ARRIMetaExt is not executable"  
  exit
fi
[[ "$INPUTMXF" =~ .*\.mxf ]] || usage "input file is not an .mxf file"
[ -d "$OUTPUTPATH" ] || usage "$OUTPUTDIR is not a valid dir"


#---WinPath configuration
INPUTMXFWINPATH=$(echo "$INPUTMXF" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )
OUTPUTDIRWINPATH=$(echo "$OUTPUTDIR" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

# predicts if the generated path is over 256 characters count. If so usage exit
GENERATEDFILECOUNT=$(echo "$OUTPUTDIRWINPATH""$FILENAME" | wc -c)
[ $GENERATEDFILECOUNT -ge 240 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."


[ -d $OUTPUTDIR ] || mkdir $OUTPUTDIR
#Generate .mxf.csv return shot duration value. Generate LUT file for all different Target display (possible use for dailies render).
SHOTDURATION=$("$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 REC-709 true | grep "Detected ARRIRAW frames:" | sed "s/[^0-9]//g") 
"$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 REC-709 false
"$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 P3-DCI true
"$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 P3-DCI false
"$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 REC-2100-PQ true
"$ARRIMetaExt" -i $INPUTMXFWINPATH -o $OUTPUTDIRWINPATH -s ";" -l --lutformat "Iridas" 33 REC-2100-PQ false

OLDLUTFILES=$(find $OUTPUTDIR | grep ".*\.cube" )
((i=1))
IFS=$'\n'
for OLDLUTFILE in $OLDLUTFILES
do
  LUTFILE[i]=$( echo "$OLDLUTFILE" | sed "s/.mxf//" | tr -d " " )
  mv "$OLDLUTFILE" "${LUTFILE[i]}"
  ((i++))
done
IFS=$OLDIFS

COPIES=$(find $OUTPUTDIR | grep " copy ([0-9])\.csv" )
IFS=$'\n'
for COPY in "$COPIES"
do
  rm $COPY
done
IFS=$OLDIFS

ARRIMETACSV="$OUTPUTDIR""/""$FILENAME"".mxf.csv"
echo -e "\n$ARRIMETACSV\n$SHOTDURATION"
exit
