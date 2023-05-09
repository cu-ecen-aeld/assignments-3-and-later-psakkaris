#!/bin/sh

if [ $# -lt 2 ]
then
  echo "usage: finder.sh <filesdir> <searchstr>"
  exit 1
fi

if [ -d $1 ]
then
    NUMFILES=$(grep -lr $2 $1 | wc -l)
    NUMLINES=$(grep -r $2 $1 | wc -l)
    echo "The number of files are ${NUMFILES} and the number of matching lines are ${NUMLINES}"
else
    echo "Error: Directory ${1} does not exists."
    exit 1
fi

