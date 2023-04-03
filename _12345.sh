#!/bin/bash
################################################################################
# Author: Fred (support@qo-op.com)
# Version: 0.1
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
################################################################################
# PUBLISHING IPNS SWARM MAP
# This script scan Swarm API layer from official bootstraps
# Then publish map of json DApp data
#
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
. "${MY_PATH}/tools/my.sh"

## LOG IN
exec 2>&1 >> ~/.zen/tmp/_12345.log

PORT=12345

    YOU=$(myIpfsApi); ## API of $USER running ipfs
    LIBRA=$(head -n 2 ~/.zen/Astroport.ONE/A_boostrap_nodes.txt | tail -n 1 | cut -d ' ' -f 2) ## SWARM#0 ENTRANCE URL

ncrunning=$(ps axf --sort=+utime | grep -w 'nc -l -p 12345' | grep -v -E 'color=auto|grep' | tail -n 1 | cut -d " " -f 2)
[[ $ncrunning ]] && echo "(≖‿‿≖) - KILLING Already Running MAP Server -  (≖‿‿≖) " && kill -9 $ncrunning

    GNODEID=$($MY_PATH/tools/ipfs_to_g1.py ${IPFSNODEID})

## RESET MEMORY
rm -Rf ~/.zen/tmp/swarm/*
## NAME PUBLISH EMPTY !!!
# ipfs name publish --allow-offline /ipfs/Qmc5m94Gu7z62RC8waSKkZUrCCBJPyHbkpmGzEePxy2oXJ
## INDICATE IPFSNODEID IS RUNNING
##############################################

mkdir -p ~/.zen/tmp/swarm
mkdir -p ~/.zen/tmp/$IPFSNODEID

MOATS=$(date -u +"%Y%m%d%H%M%S%4N")
echo "${MOATS}" > ~/.zen/tmp/${IPFSNODEID}/.MySwarm.moats

## CREATE CHAN = MySwarm_$IPFSNODEID
    CHAN=$(ipfs key list -l | grep -w "MySwarm_$IPFSNODEID" | cut -d ' ' -f 1)
    [[ ! $CHAN ]] && CHAN=$(ipfs key gen "MySwarm_$IPFSNODEID")
## PUBLISH CHANNEL IPNS
    echo "/ipns/$CHAN" > ~/.zen/tmp/$IPFSNODEID/.MySwarm


# REFRESH FROM BOOTSTRAP (COULD, SHOULD BE MY FRIENDS !)
while true; do
    start=`date +%s`
    MOATS=$(date -u +"%Y%m%d%H%M%S%4N")

    lastrun=$(cat ~/.zen/tmp/${IPFSNODEID}/.MySwarm.moats)
    duree=$(expr ${MOATS} - $lastrun)

    ## FIXING TIC TAC FOR NODE & SWARM REFRESH
    if [[ duree -gt 3600000 ]]; then

    ( ##### SUB-PROCESS
    start=`date +%s`

    ############# GET BOOTSTRAP SWARM DATA
    for bootnode in $(cat ~/.zen/Astroport.ONE/A_boostrap_nodes.txt | grep -Ev "#") # remove comments
    do

        echo "############# RUN LOOP ######### $(date)"
        ipfsnodeid=${bootnode##*/}
        mkdir -p ~/.zen/tmp/swarm/$ipfsnodeid

        addtype=$(echo ${bootnode} | cut -d '/' -f 2)
        nodeip=$(echo ${bootnode} | cut -d '/' -f 3)

            echo "Getting $nodeip : /ipns/$ipfsnodeid"
            [[ $YOU ]] && ipfs --timeout 180s get -o ~/.zen/tmp/swarm/$ipfsnodeid /ipns/$ipfsnodeid/
            echo "Updated : ~/.zen/tmp/swarm/$ipfsnodeid"

             ls ~/.zen/tmp/swarm/$ipfsnodeid

            ## ASK FOR MY MAP UPSYNC
            if [[  $addtype == "ip4" ]]; then
                echo "STATION MAP UPSYNC : curl -s http://$nodeip:12345/?${GNODEID}=${IPFSNODEID}"
                curl -s -m 10 http://$nodeip:12345/?${GNODEID}=${IPFSNODEID} -o ~/.zen/tmp/swarm/${ipfsnodeid}/map.json
            fi

    done

    ############### UPDATE MySwarm CHAN
    ls ~/.zen/tmp/swarm
    BSIZE=$(du -b ~/.zen/tmp/swarm | tail -n 1 | cut -f 1)

    ## SIZE MODIFIED => PUBLISH MySwarm_$IPFSNODEID
    [[ $BSIZE != $(cat ~/.zen/tmp/swarm/.bsize) ]] \
    && echo $BSIZE > ~/.zen/tmp/swarm/.bsize \
    && SWARMH=$(ipfs add -rwq ~/.zen/tmp/swarm/* | tail -n 1 ) \
    && ipfs name publish --key "MySwarm_$IPFSNODEID" --allow-offline /ipfs/$SWARMH


    ############# PUBLISH IPFSNODEID BALISE
    # Clean Empty Directory (inode dependancy BUG ??)
    du -b ~/.zen/tmp/${IPFSNODEID} > /tmp/du
    while read branch; do [[ $branch =~ "4096" ]] && rm -Rf $(echo $branch | cut -f 2 -d ' '); done < /tmp/du

    # Scan local cache
    ls ~/.zen/tmp/${IPFSNODEID}/
    BSIZE=$(du -b ~/.zen/tmp/${IPFSNODEID} | tail -n 1 | cut -f 1)


    ## Merge with actual online version
    ipfs get -o ~/.zen/tmp/${IPFSNODEID} /ipns/${IPFSNODEID}/
    NSIZE=$(du -b ~/.zen/tmp/${IPFSNODEID} | tail -n 1 | cut -f 1)

    ## Local / IPNS size differ => Publish
    [[ $BSIZE != $NSIZE ]] \
    && ROUTING=$(ipfs add -rwq ~/.zen/tmp/${IPFSNODEID}/* | tail -n 1 ) \
    && echo "BALISE STATION /ipns/${IPFSNODEID} INDEXES = $NSIZE octets" \
    && ipfs name publish --allow-offline /ipfs/$ROUTING

    end=`date +%s`
    echo "(*__*) MySwam Update ($BSIZE B) duration was "`expr $end - $start`' seconds.'

    ) & ##### SUB-PROCESS


    #### ACTIVATE LIBP2P PORT FORWARDINGS
    # ~/.zen/Astroport.ONE/tools/ipfs_P2P_forward.sh


    # last run recording
    echo "${MOATS}" > ~/.zen/tmp/${IPFSNODEID}/.MySwarm.moats

    else
        echo "$duree only cache life"

    fi

    HTTPSEND="HTTP/1.1 200 OK
Access-Control-Allow-Origin: \*
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET
Server: Astroport.ONE
Content-Type: application/json; charset=UTF-8

{
    \"created\" : \"${MOATS}\",
    \"hostname\" : \"$(myHostName)\",
    \"myIP\" : \"${myIP}\",
    \"ipfsnodeid\" : \"${IPFSNODEID}\",
    \"url\" : \"${myIPFS}/ipns/${IPFSNODEID}\",
    \"myswarm\" : \"${myIPFS}/ipns/${CHAN}\"
}
"
    ######################################################################################
    #  BLOCKING COMMAND nc 12345 port waiting
    echo '(◕‿‿◕) http://'$myIP:'12345 READY (◕‿‿◕)'
    REQ=$(echo "$HTTPSEND" | nc -l -p 12345 -q 1) ## # WAIT FOR 12345 PORT CONTACT

    URL=$(echo "$REQ" | grep '^GET' | cut -d ' ' -f2  | cut -d '?' -f2)
    HOSTP=$(echo "$REQ" | grep '^Host:' | cut -d ' ' -f2  | cut -d '?' -f2)
    HOST=$(echo "$HOSTP" | cut -d ':' -f 1)
    COOKIE=$(echo "$REQ" | grep '^Cookie:' | cut -d ' ' -f2)
    echo "RECEPTION : $URL"
    arr=(${URL//[=&]/ })

    #####################################################################
    ### UPSYNC STATION REQUEST /?G1PUB=g1_to_ipfs(G1PUB)&...(TODO include CODE HASH & TOKEN)
    #####################################################################
    if [[ ${arr[0]} != "" ]]; then
        ##
        GPUB=${arr[0]}
        ASTROTOIPFS=$(${MY_PATH}/tools/g1_to_ipfs.py ${arr[0]} 2>/dev/null)
        if [[ "${ASTROTOIPFS}" == "${arr[1]}" ]]; then
            echo "STATION ${GPUB} CONTACT"
            ## CLIENT KNOWS HOW TO CONVERT G1 to IPFS
            (
            mkdir -p ~/.zen/tmp/${IPFSNODEID}/swarm/${ASTROTOIPFS}
            echo "UPSYNC TO  ~/.zen/tmp/${IPFSNODEID}/swarm/${ASTROTOIPFS}"
            [[ $YOU ]] && ipfs --timeout 180s get -o ~/.zen/tmp/${IPFSNODEID}/swarm/${ASTROTOIPFS} /ipns/${ASTROTOIPFS}
            ) &

        fi
    fi

    #### 12345 NETWORK MAP TOKEN
    end=`date +%s`
    echo '(#__#) WAITING TIME was '`expr $end - $start`' seconds.'
    echo '(^‿‿^) 12345 TOKEN '${MOATS}' CONSUMED  (^‿‿^)'

done

exit 0
