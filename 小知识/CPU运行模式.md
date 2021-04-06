## 运行模式：

在Linux中，内核的开发者定义了一套框架模型来完成CPU频率动态调整这一目的，它就是CPU Freq系统。如下为CPU的几种模式（governor参数）：

1. **ondemand**：系统默认的超频模式，按需调节，内核提供的功能，不是很强大，但有效实现了动态频率调节，平时以低速方式运行，当系统负载提高时候自动提高频率。以这种模式运行不会因为降频造成性能降低，同时也能节约电能和降低温度。一般官方内核默认的方式都是ondemand。
2. interactive：交互模式，直接上最高频率，然后看CPU负荷慢慢降低，比较耗电。Interactive 是以 CPU 排程数量而调整频率，从而实现省电。InteractiveX 是以 CPU 负载来调整 CPU 频率，不会过度把频率调低。所以比 Interactive 反应好些，但是省电的效果一般。
3. conservative：保守模式，类似于ondemand，但调整相对较缓，想省电就用他吧。Google官方内核，kang内核默认模式。
4. smartass：聪明模式，是I和C模式的升级，该模式在比interactive 模式不差的响应的前提下会做到了更加省电。
5. **performance**：性能模式！只有最高频率，从来不考虑消耗的电量，性能没得说，但是耗电量。
6. powersave 省电模式，通常以最低频率运行。
7. userspace：用户自定义模式，系统将变频策略的决策权交给了用户态应用程序，并提供了相应的接口供用户态应用程序调节CPU 运行频率使用。也就是长期以来都在用的那个模式。可以通过手动编辑配置文件进行配置
8. Hotplug：类似于ondemand, 但是cpu会在关屏下尝试关掉一个cpu，并且带有deep sleep，比较省电。
   

### 一、安装cpu频率管理软件

sudo apt-get install cpufrequtils

### 二、查看CPU状态

​    cpufreq-info

### 三、把cpu调整到性能模式：

​    sudo cpufreq-set -g performance
使用上述方式,重启系统后又回到默认方式。修改默认模式:

####  1、安装sysfsutils：

​    sudo apt-get install sysfsutils

#### 2、查看当前的调节器：

cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

####  3、编辑/etc/sysfs.conf ,增加如下语句:

   sudo gedit  /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

填写需要更改的状态。



getconf LONG_BIT



查看频率信息

```
cpupower frequency-info
```

调整频率 

```
cpupower frequency-``set` `-g performance
```

## cpupower

RHEL/CentOS 7的systemd提供了cpupower.service配置

```
cat` `/lib/systemd/system/cpupower``.service``[Unit]``Description=Configure CPU power related settings``After=syslog.target` 

`[Service]``Type=oneshot``RemainAfterExit=``yes``EnvironmentFile=``/etc/sysconfig/cpupower``ExecStart=``/usr/bin/cpupower` `$CPUPOWER_START_OPTS``ExecStop=``/usr/bin/cpupower` `$CPUPOWER_STOP_OPTS` 

`[Install]``WantedBy=multi-user.target
```

配置/etc/sysconfig/cpupower

```
cat` `/etc/sysconfig/cpupower``# See 'cpupower help' and cpupower(1) for more info``CPUPOWER_START_OPTS=``"frequency-set -g performance"``CPUPOWER_STOP_OPTS=``"frequency-set -g ondemand"
```

```
[root@node1 ~]# cat /etc/sysconfig/cpupower 
# See 'cpupower help' and cpupower(1) for more info
CPUPOWER_START_OPTS="frequency-set -g performance"
CPUPOWER_STOP_OPTS="frequency-set -g ondemand"
[root@node1 ~]# cat /lib/sys
sysctl.d/ systemd/  
[root@node1 ~]# cat /lib/sys
sysctl.d/ systemd/  
[root@node1 ~]# cat /lib/systemd/system/cpupower.service 
[Unit]
Description=Configure CPU power related settings
After=syslog.target

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/sysconfig/cpupower
ExecStart=/usr/bin/cpupower $CPUPOWER_START_OPTS
ExecStop=/usr/bin/cpupower $CPUPOWER_STOP_OPTS

[Install]
WantedBy=multi-user.target
[root@node1 ~]# 
```

