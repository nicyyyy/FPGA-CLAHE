# FPGA-CLAHE
Constrast limited adaptive histogram equlization based on Verilog

设计了系统框图如图所示。将整幅图片分割成4*4=16个block，每个block对应一块深度为256的ram存储区域。像素点逐个输入，使用一个行计数器和列计数器判断像素点坐标，用坐标判断像素点所属的block，并根据灰度值生成对应地址，并进行直方图统计。初步完成统计后，遍历存储区域进行直方图累加，在此过程中对灰度级最大值进行限制和重新分配。
![image](https://github.com/nicyyyy/FPGA-CLAHE/assets/57220819/874689c6-2632-4a98-97ad-50db67422d63)

在直方图统计的过程中，同时对输入像素点进行均衡化操作。即对当前帧的像素使用上一帧的直方图计算结果进行映射，当前帧计算的直方图用于下一帧图像的均衡化。在连续的图像信号输入中，这样的做法避免了对图像进行缓存，转为缓存直方图统计结果，降低ram内存消耗。在均衡化的过程中，首先计算当前像素插值时用到的邻域block，生成对应的读地址，并且根据行列计数器的值计算出与邻域block中心点的距离，根据该距离计算插值时的各项权重。再根据权重和读地址数据计算插值后结果并输出。

# ram_cntl模块
实例化了各block区域对应的直方图存储ram，以及读写控制逻辑。由于直方图统计和均衡化同时进行，所以需要实例化32个256*16bit的双端口ram，保证前后两帧之间以及读写时序不会冲突。Ram的连接方式如下图：
![image](https://github.com/nicyyyy/FPGA-CLAHE/assets/57220819/dc3d60d1-714f-4367-924c-6c3372fc78e7)

端口a用于读取直方图统计值，包含5组32选1的数据选择器。一组数据选择器输出连接到clipper模块，用于累加直方图计算CDF，其余四组数据选择器控制端接interpolation_ctl模块，输出端接equalizer模块，用于输出灰度值映射。

端口b用于写入直方图统计值与统计值清零。清零控制信号和写block信号结果5-32译码器连接到每个ram的wr_en口。

# histogram模块
该模块完成对每个block区域内的灰度直方图统计。首先将输入像素点缓存3个周期，依次进入pixel1、pixel2、pixel3、pixel4寄存器。从第一个像素点进入开始，行、列计数器启动，根据行、列坐标判断像素点对应的block区域。

T1：读端口a地址为pixel1

T2：从端口a读入统计值，判断pixel2是否等于pixel3。若pixel2=pixel3，累加器加1，若pixel2不等于pixel3，或pixel2与pixel3不属于同一个block，累加器置1，

T3：若pixel3不等于pixel4（即T2周期中的pixel2不等于pixel3），写端口b地址为pixel3，写数据为ram中读入的统计值+累加器。反之写地址和写block信号为高阻态。

# clipper模块
该模块完成CDF的计算。当完成当前帧的均衡化和直方图统计后，该模块启动。从端口a中依次读取统计好的灰度直方图并进行累加，在延迟一个周期后将累加的值依次从端口b写回ram。累加过程中，判断每个bin的统计值是否大于阈值，将超出于阈值的部分减去，并将超出部分加入excess累加器。累加完一个block后将excess值右移8位存入寄存器，用于直方图的重新分布。

# interpolation_ctl模块
该模块计算每个像素点灰度值对应的映射区域地址，并计算插值系数。

# equalizer模块
由interpolation_ctl模块输出4个灰度值映射地址与权重后，该模块完成插值的计算。
