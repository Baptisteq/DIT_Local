#!/bin/bash
DIR=$(echo "$1" | sed "s/cygdrive\/[a-z]\///" | tr "/" "\\" 2> /dev/null )

REDLINE="C:/Program Files/REDCINE-X PRO 64-bit/REDline.exe"
# OUTPUTFILENAME="$1_RWG-Log3G10_RGB16b_"
# echo "$("$REDLINE" --i $DIR --printMeta 1)"
# "$REDLINE" --i $1 --useRMD 1 --start 0 --end 5 --format 0 --bitDepth 16 --gpuPlatform 0 --noAudio --colorSciVersion 3  --primaryDev --o $OUTPUTFILENAME
# "$REDLINE" --i $1 --useRMD 1 --cdlExport B002_C037_06288E 
"$REDLINE" --i $1 --useRMD 1 --trimFCPXlm 1 TESTTRIM