#!/bin/bash
# 使用maven编译打包源码
WORKSPACE=$1
project_name=$2
skip_test_flag=$3
function build() {

  # 编译hjc-demo
  cd ${WORKSPACE}/hjc-demo
  mvn -U clean install -Dmaven.test.skip=${skip_test_flag}
  if [ $? -ne 0 ]; then
    exit -1
    echo "Failed to build hjc-demo."
  fi

  # 拷贝产物
  RESULT="coding-saas-result"
  rm -rf ${RESULT} && mkdir ${RESULT}
  mv  hjc-demo-web/target/*.jar ${RESULT}

  # 生成 md5 保存
  md5sum ${RESULT}/*.jar > ${RESULT}/${project_name}-md5sum.txt
}

build