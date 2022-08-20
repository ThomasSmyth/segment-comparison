export SVAPORT=5700                     # port to run webpage on
if [ -z $SVAHOME ]; then
    export SVAHOME=${PWD}               # home directory for code
fi
export SVAHDB=${SVAHOME}/hdb            # hdb directory
export SVAWEB=${SVAHOME}/webpage        # location of webpage code

# 32 bit lib
export LD_LIBRARY_PATH=LD_LIBRARY_PATH:/usr/lib32/
