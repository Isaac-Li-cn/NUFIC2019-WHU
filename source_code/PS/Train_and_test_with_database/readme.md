# 代码使用说明

读了一些文章，采用这样的架构，效果比较好。

![1572487966519](/media/liyunzhe/备份/tyora_pic/1572487966519.png)

使用的时候记得修改标签和路径：

![1572488018579](/media/liyunzhe/备份/tyora_pic/1572488018579.png)

![1572488041313](/media/liyunzhe/备份/tyora_pic/1572488041313.png)

# 情况说明

如果算力不够，可以减小LSTM的规模

# 遇到问题解决

无法获取线性加速度，就使用真实加速度再训练一次，将切割的阈值适当调低