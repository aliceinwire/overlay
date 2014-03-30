#!/bin/env bash

list="$(find . -type f -iname '*.ebuild')"
for i in $list
do
    pypy="$(grep -l pypy $i)"
    for i in $pypy
    do
        ekeyword ~all $i
        ebuild $i digest
    done
done
