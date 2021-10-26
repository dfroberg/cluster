#!/usr/bin/env bash
# Requires: 
# sudo apt install figlet
# sudo apt install lolcat
# https://github.com/dty1er/kubecolor/releases
while true; do
    figlet -f slant "media" | lolcat
    kubecolor get po -n media; sleep 5; clear;
    figlet -f slant "default" | lolcat
    kubecolor get po -n default; sleep 5; clear;
    figlet -f slant "databases" | lolcat
    kubecolor get po -n databases; sleep 5; clear;
    figlet -f slant "tools" | lolcat
    kubecolor get po -n tools; sleep 5; clear;
    figlet -f slant "nodes" | lolcat
    kubecolor get nodes -owide; sleep 5; clear;
done
