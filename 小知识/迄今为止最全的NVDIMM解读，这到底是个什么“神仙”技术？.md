在计算机体系结构中，处理器CPU主频增长及多核的出现使其性能以每年70%的速度在增加，而以DRAM为主流的存储器性能每年提升约7%，这就导致了所谓的“内存墙”出现[1]。应用方面，云计算、大数据和一些高性能计算平台迫切需增加内存容量。

NVDIMM【**非易失性双列直插式内存模块（英语：non-volatile dual in-line memory module，缩写*NVDIMM*）**】就是应对这样挑战的产物，也正好能够满足相关企业提升性能的需求。

**NVDIMM技术平衡内存与闪存性能差异**

处理器与存储器间的性能差异催生了NVDIMM(Non-Volatile Dual in Memory Module，非易失内存模组)的出现。非易失性内存指的是即使在不通电的情况下，数据也不会消失。因此可以在计算机非正常掉电（unexpected power loss）、系统崩溃或正常关机的情况下，保持数据不丢失。

NVDIMM技术平衡了传统主流内存DRAM和非易失介质如Flash（闪存）/PCM（相变存储）之间的性能差。作为存储器市场的新物种，NVDIMM已在一些领域占据了一席之地，同时NVDIMM的技术标准也在不断演进来适应市场的新需求。

NVDIMM的诞生一方面解决了内存容量的需求，另一方面也解决了DRAM内存掉电易失的尴尬。图1所示为计算机的存储体系结构，以DRAM为主内存的存储器容量目前在GB级别，但DRAM具有纳秒级快速访问的优点；与之相对的NAND Flash SSD存储容量已经达到TB级别，而访问速率却在微秒级，**NVDIMM便是介于DRAM内存和NAND Flash存储之间的新型存储器，它兼顾了DRAM访问速度快和NAND Flash容量大的优点**。

![img](https://pics4.baidu.com/feed/2fdda3cc7cd98d10f2370614b9ec08087aec900a.jpeg?token=af8bad101e5a261dab8446e43afbdd8f)图1 计算机存储系统

**多种NVDIMM标准 各有千秋**

JEDEC组织定义了多种NVDIMM，包括NVDIMM-N、NVDIMM-F、NVDIMM-P（标准在研）和NVDIMM-H（标准在研）。其中，NVDIMM-P/-H属于SCM（Storage Class Memory，存储级内存）的存储器，Intel推出了和美光联合研发的SCM NVDIMM产品3DxPoint。

![img](https://pics4.baidu.com/feed/7af40ad162d9f2d361d4b8ce3e3f3a156227cc20.jpeg?token=fe7a1f4b503561b427ba8b4913cac46c)Intel和美光联合研发的SCM NVDIMM产品3

下面逐一介绍各种NVDIMM技术。

**01 NVDIMM-N：混合了DRAM与NAND**

如图2所示，NVDIMM-N是一种基于DRAM和NAND Flash的混合RDIMM（Registered DIMM，带寄存器的双列直插内存模组）模组，在常规的DDR接口上增加了供电和中断接口实现非易失[2]。

![img](https://pics6.baidu.com/feed/b999a9014c086e0615bcdb9f94dbcbf20bd1cb2c.jpeg?token=573005672c80f1da0443926385d5ad7f)图2 NVDIMM-N系统框图

正常工作时，NVDIMM作为RDIMM被Host/CPU访问，Host通过系统管理总线查询NVDIMM模组上的超级电容、NAND Flash等器件的工作状态，以此来判断模组的备份功能是否正常。

当Host异常掉电时，Host先检测到AC（交流电供电）异常，之后Host的DC（直流电）将坚持一段时间(13ms左右)的正常供电，确保CPU的ADR(Asynchronous DRAM Refresh，异步DRAM自刷新技术)将缓存数据刷到DRAM内存，并记录此次的异常掉电情况，随后NVDIMM上控制器的SAVE_n中断信号被激活来通知NVDIMM进行数据备份。

模组收到中断信号后，NVDIMM控制器先将模组的供电无损切换到超级电容，然后将DRAM中的数据全部读出，计算ECC冗余一并写入模组中的NAND Flash。当Host再次上电时，BIOS阶段将备份在NAND Flash中的数据校验后回写到DRAM，数据恢复完成后上报状态给Host，将DRAM控制权交还给Host。

由上述可见，NVDIMM-N模组是利用的NAND Flash的非易失性，在Host异常掉电时将DRAM数据备份到NAND Flash，Host重新上电时恢复数据到DRAM。也就是说模组上的NAND Flash只能被控制器访问，Host在正常工作时不能访问NAND Flash，这似乎有点浪费，于是衍生出了NVDIMM-F、NVDIMM-P、NVDIMM-H和Intel的3DxPoint。

**02 NVDIMM-F：基于DDR接口的闪存盘**

NVDIMM-F从本质上讲可以认为是一块在DDR接口上的SSD盘，与SATA/PCIe接口的SSD相比，DDR接口具有延迟低且带宽高的优点。以DDR4为例，读写延迟在纳秒级，带宽可到达3.2GT/s*64=204.8GT/s。

![img](https://pics6.baidu.com/feed/e61190ef76c6a7ef3225d7176b291f57f2de66de.jpeg?token=2a4195678618cd59dde10027275b6d5c)图3 NVDIMM-F系统框图

如图3所示，Host访问NVDIMM-F时，控制器先接收并可能缓冲操作指令和数据，之后进行与SSD控制器相似的数据缓存、映射和ECC等处理，最终操作NAND Flash。根据DDR接口延迟和带宽的特点，需要NVDIMM-F控制器具有很高的处理性能。

由于NVDIMM-F模组上仅使用了非易失的介质NAND Flash，与SSD一样，在Host异常掉电时，只需将控制器内数据刷到Flash即可，故无需外接备用电源。

**03 NVDIMM-P：NVDIMM-N与NVDIMM-F的结合**

NVDIMM-P是一款在研的标准，预计在2020年标准发布。标准的DDR4版本由三星主导，而DDR5版本由美光主导。

NVDIMM-P标准的一个核心是实现Host在正常工作时可以访问NVM(Non-Volatile Memory,非易失性存储器)。从这个意义上理解，NVDIMM-P是NVDIMM-N和NVDIMM-F的结合。

如图4所示为NVDIMM-P的系统框图，它是一种基于LRDIMM（Load Reduced DIMM，低负载双列直插内存模块）的结构[3]，即使用了DB(data buffer，数据缓冲器)提高DQ的驱动能力。

![img](https://pics5.baidu.com/feed/b812c8fcc3cec3fd03ef1430405b6439859427f8.jpeg?token=8fd7c9242a706c8dd3dd79359f8fd857)图3 NVDIMM-F系统框图

NVDIMM-P没有指定NVM是哪种非易失介质。根据对协议的研究发现，若使用NAND Flash将很难实现接口的性能指标，或许PCM/Z-NAND将是NVDIMM-P 中NVM的可能选择。

NVDIMM-P由于使用了DRAM，很可能需备用电源在Host异常时来备份数据。值得一提的是，NVDIMM-P对DDR接口进行了重定义，以此来实现模组块访问属性，与之对应的就是需Host/CPU的MC(Memory Controller，内存控制器)做适配修改，这可能成为NVDIMM-P商用的一大障碍。

**04 NVDIMM-H：在研的新型DRAM与NAND混合模组**

NVDIMM-H也是一款在研的标准，由美国的Netlist公司主导，预计在2020年发布。

![img](https://pics5.baidu.com/feed/0b7b02087bf40ad1cd0adcc0c0ffa1d9a8ecce05.jpeg?token=02dcf37aeebaee95c654429ccc1e384d)图3 NVDIMM-F系统框图

如图5所示为NVDIMM-H的系统框图，它指定了非易失介质使用NAND Flash。

NVDIMM-H本质上与NVDIMM-N类似，是一款DRAM和NAND Flash的混合模组[4]，但硬件结构方面有较大差异，CA(Command Address，指令地址)信号在PCB有stub分别到达RCD(Registering Clock Driver，寄存时钟驱动器)和控制器。DQ信号也在PCB上有stub分别到达控制器和DRAM。NVDIMM-H在Host上使用SDM(Software Defined Memory，软件定义内存)将访问的数据集中到DRAM上，与Intel的PMDK(Persistence Memory Design Kit，持久内存开发工具包)类似，其目的是减少对非易失介质NAND Flash的操作，延长寿命。对于NVDIMM-H，Host在读写NVM时，如何摆脱需Host/CPU适配修改、减少对NAND Flash的操作，提高模组性能和寿命是该标准竞争力的关键。

**05 傲腾：Intel主推的可持续内存**

Intel发布的3DxPoint包括内存和SSD两种形态，在此仅讨论内存Optane DC Persistent Memory（傲腾DC可持续内存），Intel内部名称为Apache Pass，简称AEP。

![img](https://pics7.baidu.com/feed/3801213fb80e7becfc7ea6eeb8fd093e9a506b77.jpeg?token=35b27147ff165239dee4920e5e03dde5)图6 AEP系统框图

如图6所示，AEP和NVDIMM-P硬件相似，CA（指令地址）和DQ都是先到控制器，再去分别控制DRAM和NVM。虽然Intel没有公布其与美光联合开发的Optane具体指哪种NVM，但业界普遍认为是PCM。

据称Optane介质(PCM)访问速度是NAND的1000倍，寿命是NAND的1000倍。AEP在使用时，Host利用PMDK将热数据迁移到DRAM上，减少了对PCM的访问，提高了AEP的访问性能并延长了寿命。

AEP模组上使用PMIC（Power Management IC，电源管理集成电路）来管理电源，在Host异常掉电时，板上电容供电来备份数据，摆脱了外接备用电源。根据一些AEP的实测数据[5]，随机读写速率是DRAM内存~10%，可见，NVM的随机操作性能仍是制约AEP性能的瓶颈。

**NVDIMM技术的未来：朝着SCM演进**

![img](https://pics2.baidu.com/feed/f9dcd100baa1cd1170883bfe2ec178fac2ce2d0f.jpeg?token=ba9cac58a9b79408716a2d69b04b0095)表1 不同NVDIMM比较

表1给出了文中所述各种NVDIMM的比较。新型的NVDIMM都已经是SCM，可见，NVDIMM技术朝着SCM演进。Intel在2019年数据与存储峰会上宣称，其SCM产品AEP的推广收到了不错的效果，预计在2022年AEP的市场规模将达到50亿美元。虽然SCM DIMM的发展速度喜人，但DRAM在短期内仍将作为主存储器的地位不可撼动，SCM应该只是在一些具体领域作为替代。

**国产NVDIMM 积极推进**

国内方面，紫光集团旗下的西安紫光国芯半导体公司凭借在DRAM和NAND领域深厚的技术积淀和对存储生态的准确把握，已经成功研发了一款基于DDR4的NVDIMM-N产品。

![img](https://pics4.baidu.com/feed/024f78f0f736afc35a63856225ca5bc2b64512a7.jpeg?token=96b9a80d5b26dc768d2d7fcf003c6da9)西安紫光国芯发布的NVDIMM-N 产品