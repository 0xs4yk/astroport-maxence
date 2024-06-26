#!/bin/bash
########################################################################
# Author: Fred (support@qo-op.com)
# Version: 1.0
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
########################################################################
PLAYER="$1"
[[ $PLAYER == "" ]] && PLAYER=$(cat ~/.zen/game/players/.current/.player 2>/dev/null)


##########################
# Generate G1BARRE for each wish
for g1wish in $(ls ~/.zen/game/players/$PLAYER/voeux/*/); do
    wishname=$(cat ~/.zen/game/players/$PLAYER/voeux/*/$g1wish/.title)
    wishns=$(ipfs key list -l | grep $g1wish | cut -d ' ' -f1)

    echo "MISE A JOUR G1BARRE pour VOEU $wishname : "
    echo "G1WALLET $g1wish"
    echo "G1VOEUTW  /ipns/$wishns"

    # Create last g1barre
    G1BARRE="https://g1sms.fr/g1barre/image.php?pubkey=$g1wish&target=1000&title=$wishname&node=g1.duniter.org&start_date=2022-08-01&display_pubkey=true&display_qrcode=true&progress_color=ff07a4"
    echo "curl -m 12 -o ~/.zen/tmp/g1barre.png $G1BARRE"
    rm -f ~/.zen/tmp/g1barre.png
    curl -m 12 -so ~/.zen/tmp/g1barre.png "$G1BARRE"
     # Verify file exists & non/empy before copy new version in "world/$g1wish"
    [[ ! -s ~/.zen/tmp/g1barre.png ]] && echo "No Image ! ERROR. PLEASE VERIFY NETWORK LOCATION FOR G1BARRE" && continue
    DIFF=$(diff ~/.zen/tmp/g1barre.png ~/.zen/game/world/$g1wish/g1barre.png)
    [[ $DIFF ]] && cp ~/.zen/tmp/g1barre.png ~/.zen/game/world/$g1wish/g1barre.png
    ##################################################################"
    OLDIG1BAR=$(cat ~/.zen/game/world/$g1wish/.ig1barre)

    BAL=$($MY_PATH/../tools/jaklis/jaklis.py balance -p $g1wish )
    echo "MONTANT (G1) $BAL"
    ##################################################################"
    IG1BAR=$(ipfs add -Hq ~/.zen/game/world/$g1wish/g1barre.png | tail -n 1)
    if [[ $OLDIG1BAR != "" && $OLDIG1BAR != $IG1BAR ]]; then # Update
        echo "NEW VALUE !! Updating G1VOEU Tiddler /ipfs/$IG1BAR"

        ## Replace IG1BAR "in TW" ipfs value (hash unicity is cool !!)
        sed -i "s~${OLDIG1BAR}~${IG1BAR}~g" ~/.zen/game/players/$PLAYER/ipfs/moa/index.html
        echo $IG1BAR > ~/.zen/game/world/$g1wish/.ig1barre
        echo "Update new g1barre: /ipfs/$IG1BAR"

        MOATS=$(date -u +"%Y%m%d%H%M%S%4N")
        echo "Avancement blockchain TW $PLAYER : $MOATS"
        cp ~/.zen/game/players/$PLAYER/ipfs/moa/.chain ~/.zen/game/players/$PLAYER/ipfs/moa/.chain.$MOATS

        TW=$(ipfs add -Hq ~/.zen/game/players/$PLAYER/ipfs/moa/index.html | tail -n 1)
        echo "ipfs name publish --key=$PLAYER /ipfs/$TW"
        ipfs name publish --allow-offline --key=$PLAYER /ipfs/$TW

        # MAJ CACHE TW $PLAYER
        echo $TW > ~/.zen/game/players/$PLAYER/ipfs/moa/.chain
        echo $MOATS > ~/.zen/game/players/$PLAYER/ipfs/moa/.moats
        echo "##################################################################"
        ##################################################################

    fi

    ### NO OLDIG1BAR, MEANS FIRST RUN
    if [[ $OLDIG1BAR == ""  ]]; then # CREATE Tiddler

        TEXT="<a target='_blank' href='"/ipns/${wishns}"'><img src='"/ipfs/${IG1BAR}"'></a><br><br><a target='_blank' href='"/ipns/${wishns}"'>"${wishname}"</a>"

        # NEW G1BAR TIDDLER
        echo "## Creation json tiddler : G1${wishname} /ipfs/${IG1BAR}"
        echo '[
      {
        "title": "'G1${wishname}'",
        "type": "'text/vnd.tiddlywiki'",
        "ipns": "'/ipns/$wishns'",
        "ipfs": "'/ipfs/$IG1BAR'",
        "player": "'/ipfs/$PLAYER'",
        "text": "'$TEXT'",
        "tags": "'g1voeu g1${wishname} $PLAYER'"
      }
    ]
    ' > ~/.zen/tmp/g1${wishname}.bank.json

        rm -f ~/.zen/tmp/newindex.html

        echo "Nouveau G1${wishname}  : http://127.0.0.1:8080/ipns/$ASTRONAUTENS"
        tiddlywiki --load ~/.zen/game/players/$PLAYER/ipfs/moa/index.html \
                        --import ~/.zen/tmp/g1${wishname}.bank.json "application/json" \
                        --output ~/.zen/tmp --render "$:/core/save/all" "newindex.html" "text/plain"

        echo "PLAYER TW Update..."
        if [[ -s ~/.zen/tmp/newindex.html ]]; then
            echo "Mise à jour ~/.zen/game/players/$PLAYER/ipfs/moa/index.html"
            cp -f ~/.zen/tmp/newindex.html ~/.zen/game/players/$PLAYER/ipfs/moa/index.html
        fi

        echo $IG1BAR > ~/.zen/game/world/$g1wish/.ig1barre

    fi

done
        ##############################################################
        ##############################################################
