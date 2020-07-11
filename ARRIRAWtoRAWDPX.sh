#!/bin/bash
# set -x
#------Usage------#
# Input $1 has to be a valid folder leading to valid .MXF files. Or $1 has to be a valid .MXF file.-----$2 is a valid output folder. 
usage(){
local ERROR=$1
echo "$0, $1 needs to be a proper path base leading to valid .MXF files or a proper path to a .MXF file (ex: my/acess/path/*/MyARRIRAWfile.MXF"
echo "$2 is dir where folderPerShot is generated."
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

#--test Init---#
./ARRIMetaExtract.sh "Init"
./ARRIRawDPXStill.sh "Init"
./ARRIRawDPX.sh "Init"
#---$1 is a proper path base leading to valid .R3D files---#

INPUTDIR=$1
OUTPUTDIR=$2
ARRIRAWFILES="Not-set"


#---$ Validation test----#
#is $INPUTDIR a folder ? if not, is it a .R3D file ? (False: exit)
[ -d "$OUTPUTDIR" ] && echo "OutputDir: $OUTPUTDIR is a valid folder" || usage "Output dir: $OUTPUTDIR is not a valid access path."
[ -d "$INPUTDIR" ] && echo "$INPUTDIR is a valid folder" && ARRIRAWFILES=$(find $INPUTDIR | grep "\.mxf" ) && OUTPUTPATHS=$(echo "$ARRIRAWFILES" | sed "s|$INPUTDIR|$OUTPUTDIR|" | sed "s/\(.*\/\).*$/\1/")
[ "$ARRIRAWFILES" == "" ] && usage "Dir $INPUTDIR doesn't lead to any list of .mxf file." || echo -e "Dir $INPUTDIR leads to proper .mxf files: \n$RAWREDFILES"
[[ "$INPUTDIR" =~ .*\.mxf ]] && echo "$INPUTDIR is a valid .mxf file"
[ -d "$INPUTDIR" ] || [[ "$INPUTDIR" =~ .*\.mxf ]] || usage "$INPUTDIR is not a valid dir nor a valid .R3D file."


#Extract given filename for all .mxf files
OLFIFS="$IFS"
IFS=$'\n'
((i=0))
for OUTPUTPATH in ${OUTPUTPATHS[@]}
do
  OUTPUTPATH[i]=$OUTPUTPATH
  ((i+=1))
done

((i=0))
for ARRIRAWFILE in ${ARRIRAWFILES[@]}
do
  # generate an output folder where all files will be generated
  BASEFILENAME=$(echo "$ARRIRAWFILE" | sed "s/.*\/\(.*\)\.mxf/\1/" | sed "s/[^a-zA-Z0-9_]/_/g"  )
  OUTPUTFOLDER="${OUTPUTPATH[i]}""$BASEFILENAME""/"
   [ -d "$OUTPUTFOLDER" ] || mkdir -p $OUTPUTFOLDER
     
  # generate ARRIRAW metadata files (mxf.csv/.xmp/Look LUT files for different target spaces/ASC-CDL. Store .mxf?.csv path value for future automatic Filenaming.
  # Return ShotDuaration
  ARRIMETA=$(./ARRIMetaExtract.sh $ARRIRAWFILE $OUTPUTFOLDER | tail -2 | head -n 2  )
  ARRIMETACSV=$(echo "$ARRIMETA" | tail -n 2 | head -n 1)
  SHOTDURATION=$(echo "$ARRIMETA" | tail -n 1 )

  # generate Still DPX (No look applied, no color space transform, same as native target color space (LogCWG||LogCFilm||LogCNATIVE). Store its path value.
  DPXNOMENCLATURE=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_:Target Color Space:_:Active Image Width:x:Active Image Height:_:Sensor FPS:p" )
  STILLDPXPATH=$(./ARRIRawDPXStill.sh $ARRIRAWFILE $ARRIMETACSV $OUTPUTFOLDER $DPXNOMENCLATURE $SHOTDURATION | tail -n 1 )
  
  # generate DPX sequence folder 
  DPXSEQFOLDER=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_DPXseq")
  DPXSEQPATH="$OUTPUTFOLDER""$DPXSEQFOLDER"
  [ -d $DPXSEQPATH ] || mkdir $DPXSEQPATH

  # generate ARRI RAW Dpx sequence (No look applied, no color space transform, same as native target color space (LogCWG||LogCFilm||LogCNative).
  warningTxt 1 "$DPXSEQPATH""/""$DPXNOMENCLATURE"
  DPXFILE=$(./ARRIRawDPX.sh $ARRIRAWFILE $ARRIMETACSV $DPXSEQPATH $DPXNOMENCLATURE $STILLDPXPATH $SHOTDURATION)
  warningTxt 0 "$DPXSEQPATH""/""$DPXNOMENCLATURE"
  echo "$DPXFILE"
 
  # generate Still openEXR (Color mapped to ACES2065-1 color space). Store its path value.
  EXRNOMENCLATURE=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_ACES2065-SceneLinWG_:Active Image Width:x:Active Image Height:_:Sensor FPS:p" )
  STILLEXRPATH=$(./ARRIRawDPXStill.sh  $ARRIRAWFILE $ARRIMETACSV $OUTPUTFOLDER $EXRNOMENCLATURE $SHOTDURATION "ACES" | tail -n 1  )


  # generate openEXR sequence folder
  EXRSEQFOLDER=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_openEXRseq")
  EXRSEQPATH="$OUTPUTFOLDER""$EXRSEQFOLDER"
  [ -d $EXRSEQPATH ] || mkdir $EXRSEQPATH
  
  # generate openEXR ACES2065-1 sequence
  warningTxt 1 "$EXRSEQPATH""/""$EXRNOMENCLATURE"
  EXRFILE=$(./ARRIRawDPX.sh $ARRIRAWFILE $ARRIMETACSV $EXRSEQPATH $EXRNOMENCLATURE $STILLEXRPATH $SHOTDURATION "ACES")
  warningTxt 0 "$EXRSEQPATH""/""$EXRNOMENCLATURE"
  echo "$EXRFILE"
  
  # generate AppleProres 422HQ REC709 HD Daily 
  DAILYREC709NAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_REC709_1920x1080:_:Sensor FPS:p" )
  FRAMERATE=$(./ARRIFileNaming.sh $ARRIMETACSV "Sensor FPS")
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYREC709NAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYREC709NAME" "$FRAMERATE" "422HQ" "HD" "REC709"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYREC709NAME"
  ((i+=1))
  
    # generate AppleProres 422HQ REC709_CDL HD Daily 
  DAILYREC709CDLNAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_REC709-CDLapplied_1920x1080:_:Sensor FPS:p" )
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYREC709CDLNAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYREC709CDLNAME" "$FRAMERATE" "422HQ" "HD" "REC709_CDL"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYREC709CDLNAME"
  ((i+=1))
  
    # generate AppleProres 422HQ P3-DCI HD Daily 
  DAILYRECP3NAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_P3-DCI_1920x1080:_:Sensor FPS:p" )
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYRECP3NAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYRECP3NAME" "$FRAMERATE" "422HQ" "HD" "P3-DCI"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYRECP3NAME"
  ((i+=1))
  
    # generate AppleProres 422HQ P3-DCI_CDL HD Daily 
  DAILYRECP3CDLNAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_P3-DCI-CDLapplied_1920x1080:_:Sensor FPS:p" )
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYRECP3CDLNAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYRECP3CDLNAME" "$FRAMERATE" "422HQ" "HD" "P3-DCI_CDL"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYRECP3CDLNAME"
    
    # generate AppleProres 422HQ REC2100 HD Daily 
  DAILYREC2100NAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_REC2100-PQ_1920x1080:_:Sensor FPS:p" )
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYREC2100NAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYREC2100NAME" "$FRAMERATE" "422HQ" "HD" "REC2100"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYREC2100NAME"
  ((i+=1))
  
    # generate AppleProres 422HQ REC2100_CDL HD Daily 
  DAILYREC2100CDLNAME=$(./ARRIFileNaming.sh $ARRIMETACSV "Camera Clip Name:_:Camera Model:_REC2100-PQ-CDLapplied_1920x1080:_:Sensor FPS:p" )
  warningTxt 1 "$OUTPUTFOLDER""/""$DAILYREC2100CDLNAME"
  ./FFMPEGImgToProResQT.sh "$DPXSEQPATH" "dpx" "$OUTPUTFOLDER" "$DAILYREC2100CDLNAME" "$FRAMERATE" "422HQ" "HD" "REC2100_CDL"
  warningTxt 0 "$OUTPUTFOLDER""/""$DAILYREC2100CDLNAME"
  ((i+=1))
done
IFS=$OLDIFS
exit
