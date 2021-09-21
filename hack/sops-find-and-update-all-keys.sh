#!/bin/bash
find ./cluster -name '*.sops.yaml' -exec sops updatekeys -y {} \;

