#!/bin/bash
# 从代码仓库检出代码，用于构建阶段进行源码编译
GIT_URL=e.coding.net/cloud3products
BRANCH=$1
GIT_USERNAME=$2
GIT_PASSWORD=$3

# clone
function clone() {

  # clone hjc-demo
  git clone -b ${BRANCH} https://${GIT_USERNAME}:${GIT_PASSWORD}@${GIT_URL}/*.git
  if [ $? -ne 0 ]; then
      exit -1
      echo "Failed to clone hjc-demo"
  fi
}

clone