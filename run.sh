if [ "-bash" = $0 ]; then
    dirpath="${BASH_SOURCE[0]}"
else
    dirpath="$0"
fi

export SVAHOME=$(dirname $dirpath)

eval ". $(dirname "$dirpath")/env.sh"

echo $SVAHOME

eval "q $(dirname "$dirpath")/start_webpage.q"
