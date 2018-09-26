title: "深入HashMap"
date: 2015-06-22 21:51:04
categories: Java
tags: [Java,HashMap]
---
**摘要**：JDK1.7 HashMap源码阅读
**Abstract**: Source code analysis of JDK1.7

<!-- more -->

## 概述

HashMap实现了Map接口，HashMap和Hashtable唯一的区别就是HashMap不是线程安全的，并且允许插入空值。影响HashMap性能的参数有两个：*初始大小*和*填装因子（Load Factor）*，初始大小设置HashMap中初始有多少个bucket，填装因子则设置HashMap中的元素占总容量的最大比例，超过这一比例时，HashMap将自动扩容。当Entry数量超过容量乘以填装因子时，HashMap中的元素将会被rehash到一个二倍于原来容量的新哈希表中。
一般情况下，填装因子默认设置为0.75，这个数值是空间和时间的折中。填装因子增大会减少HashMap所占空间，但会增加查找时间。为了保证效率，最好能对放入HashMap中的元素总数有一个预估，设置适当的初始大小从而避免*rehash*发生。
需要注意的是，HashMap不是线程安全的，当多个线程同时改变同一个HashMap实例的结构时（structural modification），必须有额外的同步。所谓改变HashMap的结构，就是添加或者删除Mapping。只是改变key对应的value的值，不能算改变结构。同步操作可以在额外的Object实例上同步，也可以使用`Map m = Collections.synchronizedMap(new HashMap(...));`，如果没有做正确的同步，HashMap上的并发操作会*快速失败（fail-fast）*（事实上，它并不能保证未经同步的并发修改操作绝对能够快速失败），并抛出`ConcurrentModificationException`，这个异常机制只能用来检查程序是否有潜在的BUG，不能依赖这个异常去做程序逻辑的其他判断。

![HashMap-dia](http://zuoqy.com/images/2015-06-22/1.png)

## 结构

HashMap最基本的构成单位是Entry，在HashMap内部，所有的键值对都存储在Entry数组中，如果放入HashMap的键值对有冲突，则用拉链法，把具有相同哈希值的Entry存放在一个链表中，如下图所示：

![HashMap-structure](http://zuoqy.com/images/2015-06-22/2.png)

Entry类的定义如下：

```
static class Entry<K,V> implements Map.Entry<K,V> {
    final K key;
    V value;
    Entry<K,V> next;
    int hash;

    /**
     * Creates new entry.
     */
    Entry(int h, K k, V v, Entry<K,V> n) {
        value = v;
        next = n;
        key = k;
        hash = h;
    }

    public final K getKey() {
        return key;
    }

    public final V getValue() {
        return value;
    }

    public final V setValue(V newValue) {
        V oldValue = value;
        value = newValue;
        return oldValue;
    }

    public final boolean equals(Object o) {
        if (!(o instanceof Map.Entry))
            return false;
        Map.Entry e = (Map.Entry)o;
        Object k1 = getKey();
        Object k2 = e.getKey();
        if (k1 == k2 || (k1 != null && k1.equals(k2))) {
            Object v1 = getValue();
            Object v2 = e.getValue();
            if (v1 == v2 || (v1 != null && v1.equals(v2)))
                return true;
        }
        return false;
    }

    public final int hashCode() {
        return Objects.hashCode(getKey()) ^ Objects.hashCode(getValue());
    }

    public final String toString() {
        return getKey() + "=" + getValue();
    }

    /**
     * This method is invoked whenever the value in an entry is
     * overwritten by an invocation of put(k,v) for a key k that's already
     * in the HashMap.
     */
    void recordAccess(HashMap<K,V> m) {
    }

    /**
     * This method is invoked whenever the entry is
     * removed from the table.
     */
    void recordRemoval(HashMap<K,V> m) {
    }
}
```

## 重要的属性和常量

```
// 默认的初始容量，必须是2的指数幂
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

// HashMap的最大容量
static final int MAXIMUM_CAPACITY = 1 << 30;

// 默认填装因子load factor
static final float DEFAULT_LOAD_FACTOR = 0.75f;


// 空哈希表 
static final Entry<?,?>[] EMPTY_TABLE = {};

// 哈希表，长度必须是2的整数指数幂
transient Entry<K,V>[] table = (Entry<K,V>[]) EMPTY_TABLE;

// 键值对的数量
transient int size;


// 阈值（capacity * load factor），当键值对数量超过该值时扩容
// 当表为空表时，该值是默认初始大小
int threshold;

// 填装因子
final float loadFactor;

// 哈希表结构改变（Structurally Modified）的次数
// 结构改变：键值对数量变化、rehash
// 用于快速未经同步的并发操作的失败
transient int modCount;

 // 使用替代hash算法的阈值
 // 替代Hash算法降低了String类型的key的冲突的可能性
 // 容量超过这个阈值的时候，将使用替代Hash算法
 // 这个值可由系统参数jdk.map.althashing.threshold指定
 // 当此系统参数为1时，确保总是使用替代hash算法
 // 为-1时，确保永远不适用替代hash算法
static final int ALTERNATIVE_HASHING_THRESHOLD_DEFAULT = Integer.MAX_VALUE;

/**
 * A randomizing value associated with this instance that is applied to
 * hash code of keys to make hash collisions harder to find. If 0 then
 * alternative hashing is disabled.
 */
// 用于减少key的hash code冲突
// 如果是0，表示不使用替代的hash算法
transient int hashSeed = 0;
```

`ALTERNATIVE_HASHING_THRESHOLD_DEFAULT`初始化代码：

```
// 存放虚拟机启动后才能初始化的内容
private static class Holder {
    // 使用替代hash算法的容量阈值
    static final int ALTERNATIVE_HASHING_THRESHOLD;

    static {
        String altThreshold = java.security.AccessController.doPrivileged(
            new sun.security.action.GetPropertyAction(
                "jdk.map.althashing.threshold"));

        int threshold;
        try {
            threshold = (null != altThreshold)
                    ? Integer.parseInt(altThreshold)
                    : ALTERNATIVE_HASHING_THRESHOLD_DEFAULT;

            // disable alternative hashing if -1
            if (threshold == -1) {
                threshold = Integer.MAX_VALUE;
            }

            if (threshold < 0) {
                throw new IllegalArgumentException("value must be positive integer.");
            }
        } catch(IllegalArgumentException failed) {
            throw new Error("Illegal value for 'jdk.map.althashing.threshold'", failed);
        }

        ALTERNATIVE_HASHING_THRESHOLD = threshold;
    }
}
```

##  构造方法

指定初始大小和填装因子，创建HashMap：

```
public HashMap(int initialCapacity, float loadFactor) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException("Illegal initial capacity: " +
                                           initialCapacity);
    if (initialCapacity > MAXIMUM_CAPACITY)
        initialCapacity = MAXIMUM_CAPACITY;
    if (loadFactor <= 0 || Float.isNaN(loadFactor))
        throw new IllegalArgumentException("Illegal load factor: " +
                                           loadFactor);

    this.loadFactor = loadFactor;
    threshold = initialCapacity; // 这里并没有设置table，而是设置阈值
    init(); // 空方法，用于继承
}
```

指定初始大小，创建HashMap，填装因子使用默认值 0.75

```
public HashMap(int initialCapacity) {
    this(initialCapacity, DEFAULT_LOAD_FACTOR);
}
```

默认初始大小和填装因子，创建HashMap：

```
public HashMap() {
    this(DEFAULT_INITIAL_CAPACITY, DEFAULT_LOAD_FACTOR);
}
```

根据已有的Hashmap创建，使用默认的填装因子，和根据填装因子计算出的容量：

```
public HashMap(Map<? extends K, ? extends V> m) {
    this(Math.max((int) (m.size() / DEFAULT_LOAD_FACTOR) + 1,
                  DEFAULT_INITIAL_CAPACITY), DEFAULT_LOAD_FACTOR);
    inflateTable(threshold);

    putAllForCreate(m);
}
```

## 重要内部类

### `Entry`类

```
static class Entry<K,V> implements Map.Entry<K,V> {
    final K key;
    V value;
    Entry<K,V> next;
    int hash;

    /**
     * Creates new entry.
     */
    Entry(int h, K k, V v, Entry<K,V> n) {
        value = v;
        next = n;
        key = k;
        hash = h;
    }

    public final K getKey() {
        return key;
    }

    public final V getValue() {
        return value;
    }

    public final V setValue(V newValue) {
        V oldValue = value;
        value = newValue;
        return oldValue;
    }

    public final boolean equals(Object o) {
        if (!(o instanceof Map.Entry))
            return false;
        Map.Entry e = (Map.Entry)o;
        Object k1 = getKey();
        Object k2 = e.getKey();
        if (k1 == k2 || (k1 != null && k1.equals(k2))) {
            Object v1 = getValue();
            Object v2 = e.getValue();
            if (v1 == v2 || (v1 != null && v1.equals(v2)))
                return true;
        }
        return false;
    }

    public final int hashCode() {
        return Objects.hashCode(getKey()) ^ Objects.hashCode(getValue());
    }

    public final String toString() {
        return getKey() + "=" + getValue();
    }

    /**
     * This method is invoked whenever the value in an entry is
     * overwritten by an invocation of put(k,v) for a key k that's already
     * in the HashMap.
     */
    void recordAccess(HashMap<K,V> m) {
    }

    /**
     * This method is invoked whenever the entry is
     * removed from the table.
     */
    void recordRemoval(HashMap<K,V> m) {
    }
}
```

### Iterators

```
private abstract class HashIterator<E> implements Iterator<E> {
    Entry<K,V> next;        // next entry to return
    int expectedModCount;   // For fast-fail
    int index;              // current slot
    Entry<K,V> current;     // current entry

    HashIterator() {
        expectedModCount = modCount;
        if (size > 0) { // 设置next为第一个entry
            Entry[] t = table;
            while (index < t.length && (next = t[index++]) == null)
                ;
        }
    }

    public final boolean hasNext() {
        return next != null;
    }

    final Entry<K,V> nextEntry() {
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        Entry<K,V> e = next;
        if (e == null)
            throw new NoSuchElementException();

        if ((next = e.next) == null) {
            Entry[] t = table;
            while (index < t.length && (next = t[index++]) == null)
                ;
        }
        current = e;
        return e;
    }

    public void remove() {
        if (current == null)
            throw new IllegalStateException();
        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        Object k = current.key;
        current = null;
        HashMap.this.removeEntryForKey(k);
        expectedModCount = modCount;
    }
}

private final class ValueIterator extends HashIterator<V> {
    public V next() {
        return nextEntry().value;
    }
}

private final class KeyIterator extends HashIterator<K> {
    public K next() {
        return nextEntry().getKey();
    }
}

private final class EntryIterator extends HashIterator<Map.Entry<K,V>> {
    public Map.Entry<K,V> next() {
        return nextEntry();
    }
}
```

### KeySet 

这个集合是一个代理集合，真正的数据对象是map，所以map的改动会反映在Set上，反之亦然。
此集合支持：`Iterator.remove()`、`Set.remove()`、`removeAll()`、`clear()`
不支持：`add()`和`addAll()`

```
private final class KeySet extends AbstractSet<K> {
    public Iterator<K> iterator() {
        return newKeyIterator();
    }
    public int size() {
        return size;
    }
    public boolean contains(Object o) {
        return containsKey(o);
    }
    public boolean remove(Object o) {
        return HashMap.this.removeEntryForKey(o) != null;
    }
    public void clear() {
        HashMap.this.clear();
    }
}
```
类似`HashMap.this.xxx()`是内部类调用外部类对象非静态方法时需要明确给出的，否则会调用内部类本身的`xxx()`方法。

### Values

```
private final class Values extends AbstractCollection<V> {
    public Iterator<V> iterator() {
        return newValueIterator();
    }
    public int size() {
        return size;
    }
    public boolean contains(Object o) {
        return containsValue(o);
    }
    public void clear() {
        HashMap.this.clear();
    }
}
```

## 主要方法

### clear

```
/**
 * Removes all of the mappings from this map.
 * The map will be empty after this call returns.
 */
public void clear() {
    modCount++;
    Arrays.fill(table, null);
    size = 0;
}
```

### clone

```
public Object clone() {
    HashMap<K,V> result = null;
    try {
        result = (HashMap<K,V>)super.clone();
    } catch (CloneNotSupportedException e) {
        // assert false;
    }
    if (result.table != EMPTY_TABLE) {
        result.inflateTable(Math.min(
            (int) Math.min(
                size * Math.min(1 / loadFactor, 4.0f),
                // we have limits...
                HashMap.MAXIMUM_CAPACITY),
           table.length));
    }
    result.entrySet = null;
    result.modCount = 0;
    result.size = 0;
    result.init();
    result.putAllForCreate(this);

    return result;
}
```

### containsKey

```
public boolean containsKey(Object key) {
    return getEntry(key) != null;
}
```

### containsValue

顺序查找每一个slot的下拉链表

```
public boolean containsValue(Object value) {
    if (value == null)
        return containsNullValue();

    Entry[] tab = table;
    for (int i = 0; i < tab.length ; i++)
        for (Entry e = tab[i] ; e != null ; e = e.next)
            if (value.equals(e.value))
                return true;
    return false;
}
```

### entrySet

返回的是HashMap的成员变量，如果是null，新建一个空集合。

```
public Set<Map.Entry<K,V>> entrySet() {
    return entrySet0();
}

private Set<Map.Entry<K,V>> entrySet0() {
    Set<Map.Entry<K,V>> es = entrySet;
    return es != null ? es : (entrySet = new EntrySet());
}
```

### get

如果key为null，在`table[0]`链表上查找，否则调用getEntry方法

```
public V get(Object key) {
    if (key == null)
        return getForNullKey();
    Entry<K,V> entry = getEntry(key);

    return null == entry ? null : entry.getValue();
}
```

### isEmpty
 
```
public boolean isEmpty() {
    return size == 0;
}
```

### keySet

返回map中的所有的key的集合 详见类[KeySet](#KeySet)

```
 public Set<K> keySet() {
    Set<K> ks = keySet;
    return (ks != null ? ks : (keySet = new KeySet()));
}
```

### put

将k-v放入map，如果key在map中已经存在，则用新值替换旧值。注意，HashMap允许key value为null。
如果key为null，则指定在`table[0]`拉链。 
因此，条件`get(xxx) == null` 并不能判断key-value不存在HashMap中。

```
public V put(K key, V value) {
    if (table == EMPTY_TABLE) {
        inflateTable(threshold);
    }
    if (key == null)
        return putForNullKey(value);
    int hash = hash(key);
    int i = indexFor(hash, table.length);
    for (Entry<K,V> e = table[i]; e != null; e = e.next) {
        Object k;
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) { // 注意判断条件
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }

    modCount++;
    addEntry(hash, key, value, i);
    return null;
}
```

### putAll

这里注意以下HashMap扩容的条件并不是`(m.size() + size) >= threshold`，如果`m`中的key和hashmap中的key有重复，则可能导致不必要的扩容操作。
在这个方法里，扩容的条件计算非常保守，使得最多进行一次扩容一次。

```
public void putAll(Map<? extends K, ? extends V> m) {
    int numKeysToBeAdded = m.size();
    if (numKeysToBeAdded == 0)
        return;

    if (table == EMPTY_TABLE) {
        inflateTable((int) Math.max(numKeysToBeAdded * loadFactor, threshold));
    }

    /*
     * Expand the map if the map if the number of mappings to be added
     * is greater than or equal to threshold.  This is conservative; the
     * obvious condition is (m.size() + size) >= threshold, but this
     * condition could result in a map with twice the appropriate capacity,
     * if the keys to be added overlap with the keys already in this map.
     * By using the conservative calculation, we subject ourself
     * to at most one extra resize.
     */
    if (numKeysToBeAdded > threshold) {
        int targetCapacity = (int)(numKeysToBeAdded / loadFactor + 1);
        if (targetCapacity > MAXIMUM_CAPACITY)
            targetCapacity = MAXIMUM_CAPACITY;
        int newCapacity = table.length;
        while (newCapacity < targetCapacity)
            newCapacity <<= 1;
        if (newCapacity > table.length)
            resize(newCapacity);
    }

    for (Map.Entry<? extends K, ? extends V> e : m.entrySet())
        put(e.getKey(), e.getValue());
}
```


## 内部方法

### roundUpToPowerOf2

给定一个非负整数，给出大于等于这个数的2的指数幂

```
private static int roundUpToPowerOf2(int number) {
    // assert number >= 0 : "number must be non-negative";
    return number >= MAXIMUM_CAPACITY
            ? MAXIMUM_CAPACITY
            : (number > 1) ? Integer.highestOneBit((number - 1) << 1) : 1;
}
```

### inflateTable

扩容，容量是2的指数幂。扩容后，设置下一次需要扩容的阈值。

```
private void inflateTable(int toSize) {
    // Find a power of 2 >= toSize
    int capacity = roundUpToPowerOf2(toSize);
    //设置阈值：当size达到这个值时，再次扩容
    threshold = (int) Math.min(capacity * loadFactor, MAXIMUM_CAPACITY + 1);
    table = new Entry[capacity];
    initHashSeedAsNeeded(capacity);
}
```

### initHashSeedAsNeeded

```
final boolean initHashSeedAsNeeded(int capacity) {
    boolean currentAltHashing = hashSeed != 0;
    boolean useAltHashing = sun.misc.VM.isBooted() &&
            (capacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);
    boolean switching = currentAltHashing ^ useAltHashing;
    if (switching) {
        hashSeed = useAltHashing
            ? sun.misc.Hashing.randomHashSeed(this)
            : 0;
    }
    return switching;
}
```
### getEntry

查找指定key对应的Entry。查找时，根据hash值找到table的index，然后沿着下拉链表一次顺序查找。如果没有找到，返回null。

```
final Entry<K,V> getEntry(Object key) {
    if (size == 0) {
        return null;
    }

    int hash = (key == null) ? 0 : hash(key);
    for (Entry<K,V> e = table[indexFor(hash, table.length)];
         e != null;
         e = e.next) {
        Object k;
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k)))) // 注意条件判断
            return e;
    }
    return null;
}
```
### containsNullValue

这个方法用来查找value为null的情况，这样做是为了不在每次迭代都做类似`if (value == e.value || (value != null && value.equals(e.value)))`的复杂判断，代码清晰很多。

```
 private boolean containsNullValue() {
    Entry[] tab = table;
    for (int i = 0; i < tab.length ; i++)
        for (Entry e = tab[i] ; e != null ; e = e.next)
            if (e.value == null)
                return true;
    return false;
}
```

### getForNullKey

当key为null的时候，挂在`table[0]`上，只需要查找`table[0]`上，key为null的元素Entry即可。如果没有，返回null。

```
private V getForNullKey() {
    if (size == 0) {
        return null;
    }
    for (Entry<K,V> e = table[0]; e != null; e = e.next) {
        if (e.key == null)
            return e.value;
    }
    return null;
}
```

### hash

这个方法保证hashCode改变常数被，在hash值每一位上冲突的可能性在默认的填装因子下，碰撞的次数最高位8

```
final int hash(Object k) {
    int h = hashSeed;
    if (0 != h && k instanceof String) {
        return sun.misc.Hashing.stringHash32((String) k);
    }

    h ^= k.hashCode();

    // This function ensures that hashCodes that differ only by
    // constant multiples at each bit position have a bounded
    // number of collisions (approximately 8 at default load factor).
    h ^= (h >>> 20) ^ (h >>> 12);
    return h ^ (h >>> 7) ^ (h >>> 4);
}
```




