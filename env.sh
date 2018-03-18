export SVAPORT=5700                     # port to run webpage on
if [ -z $SVAHOME ]; then
    export SVAHOME=${PWD}               # home directory for code
fi

export SVACONF=${SVAHOME}/config        # config
export SVADATA=${SVAHOME}/data          # cache data store
export SVAWEB=${SVAHOME}/webpage        # location of webpage code
export SVALOG=${SVAHOME}/logs           # log store
