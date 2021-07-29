#!/bin/bash
function check() {
  # 检查进程是否存在
  pid_count=`ps -ef |grep hjc-demo | grep -v 'grep' | wc -l`
  if [ $pid_count -eq 0 ]; then
    echo "hjc-demo启动失败"
    exit -1
    echo "hjc-demo启动失败"
  fi
}
check