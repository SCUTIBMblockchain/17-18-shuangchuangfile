## 一、底层区块链网络架构

### 最新的 Fabric 1.0 总体架构

早在 2016 年 IBM 其实就已经推出了他们的联盟链实现 Hyperledger Fabric 0.6(以下简称 Fabric 0.6) ，当时的这个版本在应用过程中实际上还存在许多问题，这也导致了这个 Fabric 版本并没有真正的被大规模应用到行业中。


图 1.1 展示了 Fabric 0.6 版本的总体架构：
![fabric 0.6](./assest/fabric0.6.jpg)

图 1.2 展示了 Fabric 0.6 版本的运行时架构：

![fabric 0.6](./assest/0.6runtime.png)


0.6版本的架构特点是：

* 结构简单： 应用-成员管理-Peer的三角形关系，主要业务功能全部集中于Peer节点；
* 架构问题：由于peer节点承担了太多的功能，所以带来扩展性、可维护性、安全性、业务隔离等方面的诸多问题，所以0.6版本在推出后，并没有大规模被行业使用，只是在一些零星的案例中进行业务验证；

针对上述问题，1.0版本做了很大的改进和重构：

图 1.3 展示了最新的 Fabric 1.0 运行时架构：
![fabric runtime](./assest/fabric-runtime.jpg)

Fabric 1.0 架构要点：

* 分拆 Peer 的功能，将 Blockchain 的数据维护和共识服务进行分离，共识服务从 Peer 节点中完全分离出来，独立为 Orderer 节点提供共识服务；
* 基于新的架构，实现多通道（channel）的结构，实现了更为灵活的业务适应性（业务隔离、安全性等方面）
支持更强的配置功能和策略管理功能，进一步增强系统的灵活性和适应性；

* 最新的 1.0 版本中，上图中的 Membership 服务已经改名为 fabric-ca


从Fabric的新架构设计的建议文档看，1.0 版本的设计目标如下：

1. chaincode 信任的灵活性：支持多个 ordering 服务节点，增强共识的容错能力和对抗 orderer 作恶的能力
2. 扩展性： 将 endorsement 和 ordering 进行分离，实现多通道（实际是分区）结构，增强系统的扩展性；同时也将 chaincode 执行、ledger、state 维护等非常消耗系统性能的任务与共识任务分离，保证了关键任务（ordering）的可靠执行
3. 保密性：新架构对于 chaincode 在数据更新、状态维护等方面提供了新的保密性要求，提高系统的业务、安全方面的能力
4. 共识服务的模块化：支持可插拔的共识结构，支持多种共识服务的接入和服务实现
架构特点

Hyperledger fabirc 1.0 版本的在 0.6 版本基础上，针对安全、保密、部署、维护、实际业务场景需求等方面进行了很多改进，特别是 Peer 节点的功能分离，给系统架构具备了支持多通道、可插拔的共识的能力。

我们现在看看 1.0版本的关键架构：



### fabric 中的区块链账本

要了解Fabric对事务的处理，首先我们需要了解Fabric中的账本，也就是实际存储和查询数据的地方。

图 1.4 为 IBM 微讲堂中对 Fabric 1.0 账本的示意图：

![data system](./assest/data-record.png)

Fabric 1.0中的账本分为3种：

1. 区块链数据，这是用文件系统存储在 Committer 节点上的。区块链中存储了 Transaction 的读写集。
2. 为了检索区块链的方便，所以用 Level DB 对其中的 Transaction 进行了索引。
3. ChainCode 操作的实际数据存储在 State Database 中，这是一个 Key Value 的数据库，Fabric 0.6 默认采用的 Level DB，1.0 也支持使用 Couch DB 作为 State Database。

三、事务提交过程
了解了Fabric中的账本，接下来我们来了解一下对这些账本的操作涉及到的Transaction。

详细可见 fabric 1.0安装配置与测试一文。

当执行a向b转账10元，我们在cli中执行的命令为：

    peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ca.example.com-cert.pem  -C mychannel -n devincc -c '{"Args":["invoke","a","b","10"]}'

当CLI中运行该命令时，相关的事务生命周期和相关账本的示例图如下：
![transaction](./assest/lifecycle.png)

其中 peer chaincode invoke 表明这是一个 Transaction 调用。-c '{"Args":["invoke","a","b","10"]}'中的 invoke 说明调用的是 example02.go 中的 invoke 函数，具体函数我们可以看看到底实现了什么功能：


## 二、智能合约：

智能合约（Smart Contract）是区块链中应用到的，时下非常热门的概念。它最重要的特性是使得交易能够在没有第三方的情况下进行，而这种交易本身是可信的。另外它还具有使交易是无法追踪、同时也是不可逆的特性。

智能合约的概念于 1995 年就已经被科学家 Nick Szabo 提出了，他将智能合约描述为一种以信息化方式传播、验证或者执行合约的计算机协议。

下面是一段引用于维基百科的描述。

> A smart contract is a computer protocol intended to digitally facilitate, verify, or enforce the negotiation or performance of a contract. Smart contracts allow the performance of credible transactions without third parties. These transactions are trackable and irreversible.

![smart-contract](./assest/smart-contract.jpg)

率先应用了诸如智能合约、分布式一致性等特性在数字货币中，并成为区块链鼻祖的比特币 (Bitcoin) 虽然通过 POW (proof of work) 实现了分布式一致性，同时使用 UTXO 模型 存储和管理底层数据结构，实现了去中心化的分布式账本，并且在一定程度上实现了『可编程』这一特点，但是它的脚本机制非常简单，只是一个基于堆栈式的脚本语言，它不仅没有函数的功能，同时也不是图灵完备的，无法实现复杂的逻辑。

Ethereum 在今天一般被视为区块链 2.0 项目，与 Bitcoin 不同，Ethereum 平台实现了图灵完备的编程语言，这样我们就能够在 Ethereum 上编写和部署智能合约，利用 Ethereum 支持的编程语言 Solidity 以及 API 实现一些复杂的功能。

## 三、分布式一致性与共识算法
从比特币为首的密码货币大火以来，新的区块链应用和基础设施等等层出不穷，区块链作为新兴的热门技术也已经被无数人所知晓和研究。但是仅仅局限于完成一两个应用并不是我们完成这个项目的终极目的，这些区块链应用的底层技术，也就是作为一个分布式网络他们又是如何工作的，是整个区块链应用的核心，也是我们学习和研究的重点内容。

无论是 Bitcoin、Hyperledger Fabric 还是 Ethereum，作为一个分布式网络，首先需要解决分布式一致性的问题。在网络中所有的节点需要对同一个提案或者值达成共识。

节点间建立共识这一问题在一个所有节点都是可以被完全信任的分布式集群中已经是一个比较难以解决的问题，更不用说在复杂的区块链网络中了。区块链网络中并没有强制要求每个节点都是可信任的节点，因此问题的复杂程度对比普通的分布式网络来说是上升了一个层次的。


对于共识算法，我们主要研究了 Hyperledger Fabric 中应用到的和一些目前已经提出的算法。

### 共识算法

无论是在哪一个分布式系统中，分布式系统的一致性问题都是必须解决的问题。具体地讲，这个问题可以描述为：如何保证一个集群中，所有节点中的数据完全相同并且能够对某个提案（Proposal）达成一致。

只有一致性这个问题得到解决之后，分布式系统才能够正常工作。而区块链中所应用的共识算法，就是这样一个用来保证分布式系统一致性的方法。

作为现在比较流行的区块链基础设施之一：Fabric 中当然也应用到了共识算法。Fabric 1.0 ，目前fabric提供的共识算法有三种：solo，kafka和PBFT

solo模式
用于开发测试的单点共识，不用介绍什么。
kafka模式
其是一种支持多通道分区的集群时序服务，可以容忍部分节点失效（crash），但不能容忍恶意节点，其基于zookeeper进行Paxos算法选举，支持2f+1节点集群，f代表失效节点个数。即kafka可以容忍少于半数的共识节点失效。
PBFT算法
其是以前版本的主流共识算法，也就是拜占庭共识算法。拜占庭算法支持（3f+1）的节点集群，f代表恶意节点的数量。恶意节点可能会做一些恶意伪造时序或者返回相反的错误的结果等，注意这里与上面失效的区别。







POW：Proof of Work，工作证明。
比特币在Block的生成过程中使用了POW机制，一个符合要求的Block Hash由N个前导零构成，零的个数取决于网络的难度值。要得到合理的Block Hash需要经过大量尝试计算，计算时间取决于机器的哈希运算速度。当某个节点提供出一个合理的Block Hash值，说明该节点确实经过了大量的尝试计算，当然，并不能得出计算次数的绝对值，因为寻找合理hash是一个概率事件。当节点拥有占全网n%的算力时，该节点即有n/100的概率找到Block Hash。

POS：Proof of Stake，股权证明。
POS：也称股权证明，类似于财产储存在银行，这种模式会根据你持有数字货币的量和时间，分配给你相应的利息。 
简单来说，就是一个根据你持有货币的量和时间，给你发利息的一个制度，在股权证明POS模式下，有一个名词叫币龄，每个币每天产生1币龄，比如你持有100个币，总共持有了30天，那么，此时你的币龄就为3000，这个时候，如果你发现了一个POS区块，你的币龄就会被清空为0。你每被清空365币龄，你将会从区块中获得0.05个币的利息(假定利息可理解为年利率5%)，那么在这个案例中，利息 = 3000 * 5% / 365 = 0.41个币，这下就很有意思了，持币有利息。

DPOS：Delegated Proof of Stake，委任权益证明。关于此协议的详细内容，可以参考最新的博文《[区块链]DPoS官方共识机制（BTS/EOS）详解》
比特股的DPoS机制，中文名叫做股份授权证明机制（又称受托人机制），它的原理是让每一个持有比特股的人进行投票，由此产生101位代表 , 我们可以将其理解为101个超级节点或者矿池，而这101个超级节点彼此的权利是完全相等的。从某种角度来看，DPOS有点像是议会制度或人民代表大会制度。如果代表不能履行他们的职责（当轮到他们时，没能生成区块），他们会被除名，网络会选出新的超级节点来取代他们。DPOS的出现最主要还是因为矿机的产生，大量的算力在不了解也不关心比特币的人身上，类似演唱会的黄牛，大量囤票而丝毫不关心演唱会的内容。

PBFT：Practical Byzantine Fault Tolerance，实用拜占庭容错算法。见前文拜占庭容错算法介绍。
PBFT是一种状态机副本复制算法，即服务作为状态机进行建模，状态机在分布式系统的不同节点进行副本复制。每个状态机的副本都保存了服务的状态，同时也实现了服务的操作。将所有的副本组成的集合使用大写字母R表示，使用0到|R|-1的整数表示每一个副本。为了描述方便，假设|R|=3f+1，这里f是有可能失效的副本的最大个数。尽管可以存在多于3f+1个副本，但是额外的副本除了降低性能之外不能提高可靠性。

以上主要是目前主流的共识算法。 
从时间上来看，这个顺序也是按该共识算法从诞生到热门的顺序来定。 
对于POW，直接让比特币成为了现实，并投入使用。而POS的存在主要是从经济学上的考虑和创新。而最终由于专业矿工和矿机的存在，让社区对这个标榜去中心化的算法有了实质性的中心化担忧，即传闻60％～70%的算力集中在中国。因此后来又出现DPOS，这种不需要消耗太多额外的算力来进行矿池产出物的分配权益方式。但要说能起到替代作用，DPOS来单独替代POW，POS或者POW＋POS也不太可能，毕竟存在即合理。每种算法都在特定的时间段中有各自的考虑和意义，无论是技术上，还是业务上。

如果跳出技术者的角度，更多结合政治与经济的思考方式在里面，或许还会跳出更多的共识算法，如结合类似PPP概念的共识方式，不仅能达到对恶意者的惩罚性质，还能达到最高效节约算力的目的也说不定。

至于说算法的选择，这里引用季总的这一段话作为结束：

一言以蔽之，共识最好的设计是模块化,例如Notary，共识算法的选择与应用场景高度相关，可信环境使用paxos 或者raft，带许可的联盟可使用pbft ，非许可链可以是pow，pos，ripple共识等，根据对手方信任度分级，自由选择共识机制，这样才是真的最优。


### Reference
[Hyperledger](https://www.hyperledger.org/)
[Github/hyperledger/fabric](https://github.com/hyperledger/fabric)
[Blockchain区块链架构设计之四：Fabric多通道和下一代账本设计](https://zhuanlan.zhihu.com/p/24605987)
[Consensus (computer science)————维基百科](https://en.wikipedia.org/wiki/Consensus_(computer_science))
[共识算法（POW,POS,DPOS,PBFT）介绍和心得————csdn](https://blog.csdn.net/lsttoy/article/details/61624287)
[区块链技术指南————gitbook](https://yeasy.gitbooks.io/blockchain_guide/content/)




