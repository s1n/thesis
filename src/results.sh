#!/bin/bash

function score() {
   local TEST="$1"
   echo "Performance against GI:"
   perl -Ilib src/score.pl --reference results/gi.dat --test "results/$TEST.dat"
   echo "Performance against SSL:"
   perl -Ilib src/score.pl --reference results/manual.dat --test "results/$TEST.dat"
}

mkdir log
for f in `ls conf/*.json`; do
   TEST=$(basename "$f" | cut -d. -f1)
   if [ "$TEST" == "gi" ];
   then
      continue
   fi
   if [ -f "results/$TEST.dat" ];
   then
      echo ""
      echo "Previously run test: $TEST"
      score "$TEST"
      continue
   fi
   echo ""
   echo "Running test: $TEST"
   perl -Ilib src/seed.pl --configfile "$f" >& "log/$TEST.log"
   score "$TEST"
done
