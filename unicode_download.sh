#!/bin/sh
set -e

url="https://unicode.org/Public/15.1.0/ucd"
# url="https://unicode.org/Public/14.0.0/ucd"
emoji_url="${url}/emoji/emoji-data.txt"

files="CaseFolding.txt DerivedNormalizationProps.txt PropList.txt \
SpecialCasing.txt CompositionExclusions.txt ScriptExtensions.txt \
UnicodeData.txt DerivedCoreProperties.txt NormalizationTest.txt Scripts.txt \
PropertyValueAliases.txt"

mkdir -p unicode

for f in $files; do
    g="${url}/${f}"
    echo -e "${f}\n"
    curl -o unicode/$f $g
done
    
curl -o unicode/emoji-data.txt $emoji_url
