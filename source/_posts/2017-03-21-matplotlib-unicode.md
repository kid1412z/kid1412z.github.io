title: "matplotlib unicode"
date: 2017-03-21 15:05:11
categories:
tags: [matplotlib,nltk]
---
**摘要**：解决matplotlib中文乱码的问题
**Abstract**:How to plot unicode using matplotlib
<!-- more -->
## 方法一

在plot之前加上如下代码：

```python
from pylab import mpl
mpl.rcParams['font.sans-serif'] = ['FangSong'] # 指定默认字体
mpl.rcParams['axes.unicode_minus'] = False     # 解决保存图像是负号'-'显示为方块的问题
```
方法的优点是不需要改动任何配置文件，缺点是每次都要加上这样的额外代码。

## 方法二

找到matplotlib 所在的安装目录，在mac下，使用anaconda2时，所在路径为：`~/anaconda2/pkgs/matplotlib-2.0.0-np111py36_0/lib/python3.6/site-packages/matplotlib/mpl-data`
然后copy其中的matplotlibrc 文件到用户目录下：

```bash
cp matplotlibrc ~/.matplotlib/
```

修改其中的：`font.sans-serif` 加上支持中文的字体，修改`axes.unicode_minus`为`False`
保存之后，删除`~/matplotlib/`下的`fontList.py3k.cache`字体缓存，重新加载程序即可。如果系统没有所选的字体，需要把字体文件拷贝到`~/anaconda2/pkgs/matplotlib-2.0.0-np111py36_0/lib/python3.6/site-packages/matplotlib/mpl-data/fonts/ttf`。

此方法的有点就是全局生效，对所有依赖该类库的程序都可以在plot中显示unicode字符。

验证：

```python
import numpy as np
import matplotlib.pyplot as plt
x = np.linspace(0, 3*np.pi, 500)
plt.plot(x, np.sin(x**2))
plt.title('中文')
plt.show()
```

<img src="http://zuoqy.com/images/2017-03-21/1.png">

> 以上方法可以解决包括nltk在内的所有用到matplotlib而不能打印中文的问题。