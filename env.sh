export SVAPORT=5700                     # port to run webpage on
if [ -z $SVAHOME ]; then
    export SVAHOME=${PWD}               # home directory for code
fi
export SVAHDB=${SVAHOME}/hdb            # hdb directory
export SVAWEB=${SVAHOME}/webpage        # location of webpage code
