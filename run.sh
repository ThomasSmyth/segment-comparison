if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

export SVAHOME=$(dirname $dirpath)
if [ $SVAHOME == "." ]; then
	SVAHOME=$PWD
fi

eval ". $(dirname "$dirpath")/env.sh"

eval "rlwrap -c -r q $(dirname "$dirpath")/start.q"
