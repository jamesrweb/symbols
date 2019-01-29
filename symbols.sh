#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "USAGE: `basename $0` [svg directory] [output directory]"
  exit 0
fi

if [ -z "$1" ] && [ -z "$2" ]; then
    echo "ERROR: Command must contain the svg and out directories, example: `basename $0` [svg directory] [output directory]"
    exit 1
fi

outputFileName="symbols.svg"
cd "$(dirname "$0")" || exit 1
svgDir=$1
outDir=$2

if [ ! -d "$svgDir" ]; then
    echo "ERROR: The svg directory specified does not exist"
    exit 1
fi

if [ ! -d "$outDir" ]; then
    echo "INFO: The out directory specified does not exist, generating now..."
    mkdir $outDir
fi

function command_exists {
    if command -v "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

function handleSvgoInstallationFailureMaybe {
    if ! command_exists svgo; then
        echo 'ERROR: An installed version of NPM is required. You can download Node which comes packaged with NPM here: https://nodejs.org/en/. Once downloaded, try running this script again.';
        exit 1
    fi
}

function installViaNpm {
    if command_exists npm; then
        echo 'INFO: NPM found on path, installing SVGO via NPM'
        npm install svgo
    else
        echo 'ERROR: As you are not using MacOS, an installed version of NPM is required. You can download Node which comes packaged with NPM here: https://nodejs.org/en/. Once downloaded, try running this script again.'
        exit 1
    fi

    handleSvgoInstallationFailureMaybe
}

function installViaBrew {
    if command_exists brew; then
        echo 'INFO: Brew found on path, installing SVGO via Brew'
        brew install svgo
    else
        installBrew
        installViaBrew
    fi

    handleSvgoInstallationFailureMaybe
}

function installBrew {
    echo 'INFO: Installing Brew on PATH'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function isMac() {
    return "$(uname)" == "Darwin"
}

function installSvgo() {
    if [ isMac ]; then
        installViaBrew
    else
        installViaNpm
    fi
}

if ! command_exists svgo; then
  echo 'INFO: svgo is not installed.'
  echo 'INFO: Attempting to install svgo.'
  installSvgo
fi

if [ -d "$outDir" ]; then
  echo "Removing old dist directory"
  rm -rf $outDir
fi

cp -av $svgDir $outDir

echo "<svg xmlns='http://www.w3.org/2000/svg' style='display: none;'>" >> $outDir/$outputFileName
for i in `find "$outDir" -type f -name \*.svg ! -name "$outputFileName"`
do
    [ -f "$i" ] || break
    base=$(basename -- "$i")
    filename="${base%.*}"
    svgo $i
    replacer1="s/<svg /<symbol id='icon-$filename' /g"
    replacer2="s/\/svg>/\/symbol>/g"
    sed -i "$replacer1" $i
    sed -i "$replacer2" $i
    cat $i >> $outDir/$outputFileName
    rm $i
done
echo "</svg>" >> $outDir/$outputFileName
echo "INFO: Symbols generation and optimization complete"