### 背景

> 项目组已经有个`分布式锁`注解（参考前文《记一次分布式锁注解化》），但是在设置锁过期时间时，需要去预估业务耗时时间，如果锁的过期时间能根据业务运行时间自动调整，那使用的就更方便了。

### 思路

思路参考了`redisson`：

1. 保留原先的可自定义设置过期时间，只有在`没有设置过期时间（过期时间为默认值0）`的情况下，才会启动自动延长。
2. 申请锁时，设置一个`延长过期时间`，定时每隔`延长过期时间`的三分之一时间就重新设置`过期时间`（`时期时间`值为`延长过期时间`）。
3. 为了防止某次业务由于异常而出现`任务持续很久`，从而长时间占有了锁，添加`最大延期次数`参数。

### 加锁

1. 用一个`Map`来存储需要续期的`任务信息`。
2. 在加锁成功之后将`任务信息`放入`Map`，并启动延迟任务，延迟任务在执行`延期动作`前先检查下`Map`里锁数据是不是还是被当前任务持有。
3. 每次续期任务完成并且成功之后，就再次启动延迟任务。

##### 申请锁

复用之前的`加锁`方法，把`延长过期时间`作为`加锁过期时间`。

```
public Lock acquireAndRenew(String lockKey, String lockValue, int lockWatchdogTimeout) {
    return acquireAndRenew(lockKey, lockValue, lockWatchdogTimeout, 0);
}

public Lock acquireAndRenew(String lockKey, String lockValue, int lockWatchdogTimeout, int maxRenewTimes) {
    if (lockKey == null || lockValue == null || lockWatchdogTimeout <= 0) {
        return new Lock(this).setSuccess(false).setMessage("illegal argument!");
    }
    Lock lock = acquire(lockKey, lockValue, lockWatchdogTimeout);
    if (!lock.isSuccess()) {
        return lock;
    }
    expirationRenewalMap.put(lockKey, new RenewLockInfo(lock));
    scheduleExpirationRenewal(lockKey, lockValue, lockWatchdogTimeout, maxRenewTimes, new AtomicInteger());
    return lock;
}
```

##### 定时续期

当前锁还未被释放（`Map里还有数据`），并且当前`延期`任务执行成功，则继续下一次任务。

```
private void scheduleExpirationRenewal(String lockKey, String lockValue, int lockWatchdogTimeout,
        int maxRenewTimes, AtomicInteger renewTimes) {
    ScheduledFuture<?> scheduledFuture = scheduledExecutorService.schedule(() -> {
        try {
            if (!renewExpiration(lockKey, lockValue, lockWatchdogTimeout)) {
                log.debug("dislock renew[{}:{}] fail!", lockKey, lockValue);
                return;
            }
            if (maxRenewTimes > 0 && renewTimes.incrementAndGet() == maxRenewTimes) {
                log.info("dislock renew[{}:{}] override times[{}]!", lockKey, lockValue, maxRenewTimes);
                return;
            }
            scheduleExpirationRenewal(lockKey, lockValue, lockWatchdogTimeout, maxRenewTimes, renewTimes);
        } catch (Exception e) {
            log.error("dislock renew[{}:{}] error!", lockKey, lockValue, e);
        }
    }, lockWatchdogTimeout / 3, TimeUnit.MILLISECONDS);
    RenewLockInfo lockInfo = expirationRenewalMap.get(lockKey);
    if (lockInfo == null) {
        return;
    }
    lockInfo.setRenewScheduledFuture(scheduledFuture);
}

private boolean renewExpiration(String lockKey, String lockValue, int lockWatchdogTimeout) {
    RenewLockInfo lockInfo = expirationRenewalMap.get(lockKey);
    if (lockInfo == null) {
        return false;
    }
    if (!lockInfo.getLock().getLockValue().equals(lockValue)) {
        return false;
    }
    List<String> keys = Lists.newArrayList(lockKey);
    List<String> args = Lists.newArrayList(lockValue, String.valueOf(lockWatchdogTimeout));
    return (long) jedisTemplate.evalsha(renewScriptSha, keys, args) > 0;
}
```

##### 延期脚本

```
public void init() {
    ……
    String renewScript = "if redis.call('get',KEYS[1]) == ARGV[1] then \n" +
            "     redis.call('pexpire', KEYS[1], ARGV[2]) \n" +
            "     return 1 \n " +
            " end \n" +
            " return 0";
    renewScriptSha = jedisTemplate.scriptLoad(renewScript);
}
```

### 释放

执行`释放`之前，先将数据从`Map`里清除掉。

```
/**
 * @param lock
 * @return boolean
 */
public boolean removeRenew(Lock lock) {
    return expirationRenewalMap.remove(lock.getLockKey()) != null;
}

/**
 * @param lock
 */
public boolean release(Lock lock) {
    if (!ifReleaseLock(lock)) {
        return false;
    }
    // 放在redis脚本前面，防止redis删除失败，而map没有清理，从而导致redis无限期续期
    try {
        RenewLockInfo lockInfo = expirationRenewalMap.get(lock.getLockKey());
        if (lockInfo != null) {
            ScheduledFuture<?> scheduledFuture = lockInfo.getRenewScheduledFuture();
            if (scheduledFuture != null) {
                scheduledFuture.cancel(false);
            }
        }
    } catch (Exception e) {
        log.error("dislock cancel renew scheduled[{}:{}] error!", lock.getLockKey(), lock.getLockValue(), e);
    }
    removeRenew(lock);
    List<String> keys = Lists.newArrayList(lock.getLockKey());
    List<String> args = Lists.newArrayList(lock.getLockValue());
    return (long) jedisTemplate.evalsha(releaseScriptSha, keys, args) > 0;
}
```

### 注解改造

##### 注解类

注解增加两个参数，并且原先的过期时间参数默认值改为`0`，即默认启动`自动延期`，同时要注意对`ifExpireWhenFinish`字段的兼容。

```
@Target(value = {ElementType.METHOD})
@Retention(value = RetentionPolicy.RUNTIME)
public @interface DisLock {

    int DEFAULT_EXPIRE = -1;
    /**
     * 默认续期时间加上默认续期次数，结果是：默认自动续期一个小时（30000 / 3 * 360）
     */
    int DEFAULT_LOCK_WATCHDOG_TIMEOUT = 30000;
    int DEFAULT_RENEW_TIMES = 360;

    …… // 其他参数
    /**
     * 结束之后是否删除key，如果是false，
     * 1）非自动续期：不删除key，让key自动过期
     * 2）自动续期：不删除key，但是取消自动续期，让key自动过期
     *
     * @return boolean
     * @author
     * @date 2020-06-05 11:04
     */
    boolean ifExpireWhenFinish() default true;    
    /**
     * 默认key过期时间，单位毫秒
     *
     * @return long
     * @author
     * @date 2020-03-17 22:50
     */
    int expire() default DEFAULT_EXPIRE;

    /**
     * 监控锁的看门狗超时时间，单位毫秒，参数用于自动续约过期时间
     * 参数只适用于分布式锁的加锁请求中未明确使用expire参数的情况(expire等于默认值DEFAULT_EXPIRE)。
     *
     * @return int
     * @author
     * @date 2020-10-14 11:08
     */
    int lockWatchdogTimeout() default DEFAULT_LOCK_WATCHDOG_TIMEOUT;

    /**
     * 最大续期次数，用于防止业务进程缓慢在导致长时间占有锁
     *
     * @return int 大于0时有效，小于等于0表示无限制
     * @author
     * @date 2020-10-15 16:23
     */
    int maxRenewTimes() default DEFAULT_RENEW_TIMES;
}
```

##### 注解处理类

```
JedisDistributedLock.Lock lock = jedisDistributedLock.acquire(key, value, disLock.expire());
```

改成

```
JedisDistributedLock.Lock lock;
if (ifRenew(disLock)) {
    lock = jedisDistributedLock
            .acquireAndRenew(key, value, disLock.lockWatchdogTimeout(), disLock.maxRenewTimes());
} else {
    lock = jedisDistributedLock.acquire(key, value, disLock.expire());
}

protected boolean ifRenew(DisLock disLock) {
    return disLock.expire() == DisLock.DEFAULT_EXPIRE;
}
```

`final`块释放锁时，也要做调整：

```
if (lock != null) {
    if (disLock.ifExpireWhenFinish()) {
        jedisDistributedLock.release(lock);
    } else if (ifRenew(disLock)) {
        jedisDistributedLock.removeRenew(lock);
    }
}
```