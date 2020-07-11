#!/bin/bash

#----usage----#
usage(){
local ERROR=$1
echo "$0, $1 requires to be a valid access path to a .RMD file. $2 needs to be a valid output filename"
echo "ERROR: $ERROR"
echo "$1 doesn't not exist."
exit
}
#----INPUT----#
INPUTRMD=$1
OUTPUTFILE=$2


#----validation----#
[[ "$INPUTRMD" =~ "None" ]] && usage " RMD file hasn't bee found its value is set to: $INPUTRMD"
[[ "$INPUTRMD" =~ .*\.RMD ]] && echo "$INPUTRMD is a valid .RMD file" || usage "$INPUTRMD is not a valid access path to a .RMD file"
[ -f $INPUTRMD ] && echo "$INPUTRMD exists" || usage "$INPUTRMD doesn't exist."
# predicts if the generated path is over 256 characters count. If so usage exit
OUTPUTFILECOUNT=$(echo "$OUTPUTFILE" | wc -c)
[ $OUTPUTFILECOUNT -ge 256 ] && usage "Total character count of the generated file (including its path) is over or equal to 256 characters."
#----Store RMD value in var----#
RMD=$(echo $INPUTRMD)
#---Convert CDL elements (SOP-S) from .RMD to a lefit ASC (SOP-S).CDL file.
RMDSlope=$(xmllint --xpath "//Slope/text()" $RMD | head -2 | tail -1)
RMDOffset=$(xmllint --xpath "//Offset/text()" $RMD | head -2 | tail -1)
RMDPower=$(xmllint --xpath "//Power/text()" $RMD | head -2 | tail -1)
RMDSaturation=$(xmllint --xpath "//Saturation/text()" $RMD | head -2 | tail -1)



echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ColorDecisionList>
    <ColorDecision>
        <ColorCorrection>
            <SOPNode>
                <Description></Description>
                <Slope>$RMDSlope</Slope>
                <Offset>$RMDOffset</Offset>
                <Power>$RMDPower</Power>
            </SOPNode>
            <SATNode>
                <Saturation>$RMDSaturation</Saturation>
            </SATNode>
        </ColorCorrection>
    </ColorDecision>
</ColorDecisionList>" >$OUTPUTFILE.cdl
exit
