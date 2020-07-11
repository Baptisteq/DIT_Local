#!/bin/bash
# set -x
#---IFS store value---#
OLDIFS=$IFS

#---Usage---#
usage(){
echo "$0, $1 needs to be a valid path to a .*_REDMetadata.txt file generated by REDRMDMetaTxt.sh"
echo "$2 needs to be a string for each field is separated by \":\""
exit
}
META=$(cat $1)

NAMEEXPRESSION=$2
[[ $NAMEEXPRESSION == "PrimaryDev" ]] && NAMEEXPRESSION="Clip Name:_:Sensor Name:_:RWG_Log3G10:_:Frame Width:x:Frame Height:_:FPS:p_date:Date:_:Total Frames:fn:"

IFS=$':'
for var in $NAMEEXPRESSION
do
  if [[ "$var" != "" ]] && [[ "$var" != "Color Space" ]] && [[ "$var" != "Gamma Space" ]] ; then
  IFS=$OLDIFS
  VALUE=$(echo "$META" | grep "^$var:" | sed "s/.*:[\t\s]*\([a-zA-Z0-9: _-]*\)/\1/" | tr " " "-" | tr ":" "x" | tr -d "\r" )
    if [[ "$VALUE" == "" ]]; then
    FILENAME="$FILENAME""$var"
    else
    FILENAME="$FILENAME""$VALUE"
  fi
  elif [[ "$var" == "Color Space" ]]; then
  VALUE=$(echo "$META" | grep "^$var:" | sed "s/.*:[\t\s]*\([a-zA-Z0-9 _-]*\)/\1/" | tr " " "-" | tr -d "\r")
    case "$VALUE" in
      "2") VALUE="REDspace";;
      "0") VALUE="CameraRGB";;
      "1") VALUE="rec709";;
     "11") VALUE="REDspace";;
     "12") VALUE="CameraRGB";;
     "13") VALUE="rec709";;
     "14") VALUE="REDcolor";;
     "15") VALUE="sRGB";;
      "5") VALUE="Adobe1998";;
     "18") VALUE="REDcolor2";;
     "19") VALUE="REDcolor3";;
     "20") VALUE="DRAGONcolor";;
     "21") VALUE="XYZ";;
     "22") VALUE="REDcolor4";;
     "23") VALUE="DRAGONcolor2";;
     "24") VALUE="rec2020";;
     "25") VALUE="REDWideGamutRGB";;
    esac
  FILENAME="$FILENAME""$VALUE"
  elif  [[ "$var" == "Gamma Space" ]]; then
  VALUE=$(echo "$META" | grep "^$var:" | sed "s/.*:[\t\s]*\([a-zA-Z0-9 _-]*\)/\1/" | tr " " "-" | tr -d "\r")
  case "$VALUE" in
     "-1") VALUE="lin";;
      "1") VALUE="rec709";;
      "2") VALUE="sRGB";;
      "3") VALUE="REDlog";;
      "4") VALUE="PDLog985";;
      "5") VALUE="PDLog685";;
      "6") VALUE="PDLogCustom";;
     "14") VALUE="REDspace";;
     "15") VALUE="REDgamma";;
     "27") VALUE="REDLogFilm";;
     "28") VALUE="REDgamma2";;
     "29") VALUE="REDgamma3";;
     "30") VALUE="REDgamma4";;
     "31") VALUE="HDR-2084";;
     "32") VALUE="BT1886";;
     "33") VALUE="Log3G12";;
     "34") VALUE="Log3G10";;
        *) VALUE="$VALUE";;
  esac
  FILENAME="$FILENAME""$VALUE"
  fi
done
IFS=$OLDIFS

echo "$FILENAME"
exit