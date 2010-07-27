#!/bin/bash

mkdir -p moby/dict
mkdir -p moby/thes
wget http://www.gutenberg.org/dirs/etext02/mword10.zip -P moby/dict
wget http://www.gutenberg.org/dirs/etext02/mthes10.zip -P moby/thes
cd moby/dict
unzip mword10.zip
rm -f mword10.zip
cd ../thes
unzip mthes10.zip
rm mthes10.zip
cd ../../
