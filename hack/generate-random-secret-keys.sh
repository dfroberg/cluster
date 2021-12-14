#!/bin/bash
LENGTH=64
tr -cd '[:alnum:]' < /dev/urandom \
  | fold -w "${LENGTH}"           \
  | head -n 1                     \
  | tr -d '\n'                    \
  | tee actualSecretContent.txt   \
  ; echo