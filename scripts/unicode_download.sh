#!/bin/sh
set -e

version="${2:-14.0.0}"

url="https://unicode.org/Public/$version/ucd"
# url="https://unicode.org/Public/14.0.0/ucd"
emoji_url="${url}/emoji/emoji-data.txt"

files="CaseFolding.txt DerivedNormalizationProps.txt PropList.txt \
SpecialCasing.txt CompositionExclusions.txt ScriptExtensions.txt \
UnicodeData.txt DerivedCoreProperties.txt NormalizationTest.txt Scripts.txt \
PropertyValueAliases.txt"

dir=unicode-$version

mkdir -p $dir

for f in $files; do
    g="${url}/${f}"
    echo $f
    curl -o $dir/$f $g
done

curl -o $dir/emoji-data.txt $emoji_url
