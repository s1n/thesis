#!/bin/bash

function score() {
   local TEST="$1"
   local REFLEX="results/gi.dat"
   #local REFLEX="$2" || "results/gi.dat"
   echo "Performance against GI ($REFLEX):"
   perl -Ilib src/score.pl --reference "$REFLEX" --test "results/$TEST.dat"
   #perl -Ilib src/score.pl --reference results/gi.dat --test "results/$TEST.dat"
   echo "Performance against SSL:"
   perl -Ilib src/score.pl --reference results/manual.dat --test "results/$TEST.dat"
}

function runtest() {
   local TEST="$1"
   local EXTRAARGS="$2"
   echo ""
   echo "Running test: $TEST $EXTRAARGS to $TEST.dat"
   perl -Ilib src/seed.pl --configfile "conf/$TEST.json" --lexicon "results/$TEST.dat" --stripwords data/stripwords.txt "$EXTRAARGS" >& "log/$TEST.log"
   score $TEST $EXTRAARGS
}

function runboosting() {
   local TEST="$1"
   for algo in ada inv; do
      for iter in 3 10; do
         BOOSTTEST=$TEST"_"$algo$iter
         #echo "TEST=$NEWTEST"
         BOOSTALGO=`echo "$algo" | { dd bs=1 count=1 conv=ucase 2>/dev/null; cat; }`
         runtest "$BOOSTTEST", "--boost-iter $iter --lexicon $BOOSTTEST.dat --boost $BOOSTALGO"Boost" --boost-ref results/manual.dat"
         score $BOOSTTEST "results/boost_test.dat"
      done;
   done
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

   runtest "$TEST"
   #runboosting "$TEST"

done
