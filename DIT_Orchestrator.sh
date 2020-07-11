#!/bin/bash
# set -x
#------Usage------#
# Input $1 has to be a valid folder leading to valid .R3D files. Or $1 has to be a valid .R3D file.-----$2 is a valid output folder. 
usage(){
local ERROR=$1
echo "$0, $1 needs to be a proper path base leading to valid .R3D files or a proper path to a .R3D file (ex: my/acess/path/*/MyREDfile.R3D."
echo "$2 is dir where folderPerShot is generated."
echo "$3 is optionnal dir where RMD file are possibly stored (rather than attached along with .R3D matching files)."
echo "error: $ERROR"
exit
}

#---Warning Text file ----#
# adverts users that a file or folder is still in transcode.
warningTxt(){
# Encode status 1=>Encoding 2=> not encoding/done encoding #
ENCODESTATUS=$1
INPUT=$2
WARNINGTEXTFILE="$INPUT""___ENCODE_WIP_DO_NOT_USE.txt"
[ "$ENCODESTATUS" == "1" ] && [ -f $WARNINGTEXTFILE ] && rm $WARNINGTEXTFILE
[ "$ENCODESTATUS" == "1" ] && echo "" >$WARNINGTEXTFILE
[ "$ENCODESTATUS" == "0" ] && rm $WARNINGTEXTFILE
}

#---$1 is a proper path base leading to valid .R3D files---#

INPUTDIR=$1
OUTPUTDIR=$2
RMDMASTERDIR=$3
RAWREDFILES="Not-set"
RAWDPXPATH="D:/TEST_DIT/DAY_0/200_RAWDPX"
PROXYPATH="D:/TEST_DIT/DAY_0/300_PROXY"

#---$ Validation test----#
#is $INPUTDIR a folder ? if not, is it a .R3D file ? (False: exit)
[ -d "$OUTPUTDIR" ] && echo "OutputDir: $OUTPUTDIR is a valid folder" || usage "Output dir: $OUTPUTDIR is not a valid access path."
[ -d "$INPUTDIR" ] && echo "$INPUTDIR is a valid folder" && RAWREDFILES=$(find $INPUTDIR | grep "\.R3D" ) && OUTPUTPATHS=$(echo "$RAWREDFILES" | sed "s|$INPUTDIR|$OUTPUTDIR|" | sed "s/\(.*\/\).*$/\1/")
[ "$RAWREDFILES" == "" ] && usage "Dir $INPUTDIR doesn't lead to any list of .R3D file." || echo -e "Dir $INPUTDIR leads to proper .R3D files: \n$RAWREDFILES"
[[ "$INPUTDIR" =~ .*\.R3D ]] && echo "$INPUTDIR is a valid .R3D file"
[ -d "$INPUTDIR" ] || [[ "$INPUTDIR" =~ .*\.R3D ]] || usage "$INPUTDIR is not a valid dir nor a valid .R3D file."
[ -d "$RMDMASTERDIR" ] && echo "$RMDMASTERDIR is a valid folder"
#--- Script test ----#
./REDLineTranscode.sh "Init"
./REDLineProxy.sh "Init"
./REDCheckforRMD.sh "Init"
./REDLineDailies.sh "Init"
#Extract given filename for all .R3D files
OLFIFS="$IFS"
IFS=$'\n'
((i=0))
for OUTPUTPATH in ${OUTPUTPATHS[@]}
do
  OUTPUTPATH[i]=$OUTPUTPATH
  ((i+=1))
done

((i=0))
for RAWREDFILE in ${RAWREDFILES[@]}
do
  # generate an output folder where all files will be generated
  BASEFILENAME[i]=$(echo "$RAWREDFILE" | sed "s/.*\/\(.*\)\.R3D/\1/" | sed "s/[^a-zA-Z0-9_]/_/g"  )
  OUTPUTFOLDER="$OUTPUTPATH""$BASEFILENAME""/"
  [ -d "$OUTPUTFOLDER" ] || mkdir -p $OUTPUTFOLDER
  
  # check if .RMD is available, if so store its path value and copy it on output folder.
  RMDFILE=$(./REDCheckforRMD.sh "$RAWREDFILE" "$RMDMASTERDIR")
  [[ "$RMDFILE" != "None" ]] && RMDFILENAME=$(echo "$RMDFILE" | sed "s/.*\/\(.*\)\.RMD/\1/" | sed "s/[^a-zA-Z0-9_]/_/g")".RMD" && RMDCOPYPATH="$OUTPUTFOLDER""$RMDFILENAME"
  [ -f $RMDCOPYPATH ] && rm $RMDCOPYPATH 
  [[ "$RMDFILE" != "None" ]] && cp $RMDFILE $RMDCOPYPATH
  
  # generate REDLINE printmeta value on a formated.txt file (based on if RMD has been attached or not along with the .R3D file).
  REDMETATXTPATH=$(./REDRMDMetaTxt.sh $RAWREDFILE $RMDFILE $OUTPUTFOLDER)
  
  # generate ASC (SOP-S).CDL file
  CDLOUTPUTPATH="$OUTPUTFOLDER""$RMDFILENAME""_SOP-S"
  ./RMDtoASCCDL.sh $RMDFILE $CDLOUTPUTPATH
  
  # generate Still DPX (sharing same spec as per DPX RAW)
  DPXNOMENCLATURE=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:RWG-Log3G10:_:Frame Width:x:Frame Height:_:FPS;p" )
  echo $DPXNOMENCLATURE
  STILLDPXPATH=$(./REDLineStill.sh  $RAWREDFILE $OUTPUTFOLDER $DPXNOMENCLATURE 16 3)
  
  # generate DPX sequence folder
  DPXSEQFOLDER=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:RWG-Log3G10:_:Frame Width:x:Frame Height:_DPX")
  DPXSEQPATH="$OUTPUTFOLDER""$DPXSEQFOLDER"
  [ -d $DPXSEQPATH ] || mkdir $DPXSEQPATH
  
  # generate DPX  RwG Log3G10 sequence
  warningTxt 1 "$DPXSEQPATH""/""$DPXNOMENCLATURE"
    ./REDLineTranscode.sh $RAWREDFILE $DPXSEQPATH $DPXNOMENCLATURE 16 3 $STILLDPXPATH
  warningTxt 0 "$DPXSEQPATH""/""$DPXNOMENCLATURE"
  
  # generate openEXR sequence folder
  EXRSEQFOLDER=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:ACES2065-1-Lin16float:_:Frame Width:x:Frame Height:_EXR")
  EXRSEQPATH="$OUTPUTFOLDER""$EXRSEQFOLDER"
  [ -d $EXRSEQPATH ] || mkdir $EXRSEQPATH
  
  # generate openEXR ACES2065-1 sequence
  EXRNOMENCLATURE=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:ACES2065-1-Lin16float:_:Frame Width:x:Frame Height:_:FPS:p" )
  warningTxt 1 "$EXRSEQPATH""/""$EXRNOMENCLATURE"
    ./REDLineTranscodeExrACES.sh $RAWREDFILE $EXRSEQPATH $EXRNOMENCLATURE
  warningTxt 0 "$EXRSEQPATH""/""$EXRNOMENCLATURE"
  
  # encode Proxy Prores 422 HQ HD REC709BT1886
  PROXYNOMENCLATURE=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:FPS:p_date:Date:_TCin:Abs TC:_ProxyHD_WMK" )
  PROXYOUTPUTPATH="$OUTPUTFOLDER""$PROXYNOMENCLATURE"
  warningTxt 1 "$PROXYOUTPUTPATH"
  ./REDLineProxy.sh $RAWREDFILE $PROXYOUTPUTPATH 0 3 3 3 32 1 1080 0 "For_Editing"
  warningTxt 0 "$PROXYOUTPUTPATH"
  
  # generate Daily UHD HDR10 (REC.2020 PQ ST2084) for QC.
  DAILYUHDHDRNOMENCLATURE=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:Sensor Name:_IDT-RWG-Log3G10:_IPP2_ODT-REC2020-ST-2084_3840x2160:_:FPS:p_date:Date:_Daily" )
  DAILYUHDHDROUTPUTPATH="$OUTPUTFOLDER""$DAILYUHDHDRNOMENCLATURE"
  warningTxt 1 "$DAILYUHDHDROUTPUTPATH"
  ./REDLineDailies.sh $RAWREDFILE "$DAILYUHDHDROUTPUTPATH" 5 3 2 3 31 24 3840
  warningTxt 0 "$DAILYUHDHDROUTPUTPATH"
  
  # encode daily HD SDR (rec709 Bt1886) for QC
  DAILYHDSDRNOMENCLATURE=$(./REDFileNaming.sh $REDMETATXTPATH "Clip Name:_:Sensor Name:_IDT-RWG-Log3G10:_IPP2_ODT-REC709-BT1886_1920x1080:_:FPS:p_date:Date:_Daily" )
  DAILYHDSDROUTPUTPATH="$OUTPUTFOLDER""$DAILYHDSDRNOMENCLATURE"
  warningTxt 1 "$DAILYHDSDROUTPUTPATH"
  ./REDLineDailies.sh $RAWREDFILE "$DAILYHDSDROUTPUTPATH" 0 3 3 3 32 1 1920
  warningTxt 0 "$DAILYHDSDROUTPUTPATH"
  ((i+=1))
done
IFS=$OLDIFS
exit
