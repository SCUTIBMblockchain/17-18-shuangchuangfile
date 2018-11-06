## fabric1.0 安装配置与测试

下载 Compose 模板文件
$ git clone https://github.com/yeasy/docker-compose-files
进入 hyperledger/1.0 目录，查看包括若干模板文件，功能如下。

orderer-base.yaml, peer-base.yaml, docker-compose-base.yaml: 包含 peer 和 orderer 节点的基础服务模板。

docker-compose-1peer.yaml: 使用自定义的 channel 启动一个最小化的环境，包括 1 个 peer 节点、1 个 orderer 节点、1 个 CA 节点、1 个 cli 节点。

docker-compose-2orgs-4peers.yaml: 使用自定义的 channel 启动一个环境，包括 4 个 peer 节点、1 个 orderer 节点、1 个 CA 节点、1 个 cli 节点。

docker-compose-2orgs-4peers-couchdb.yaml: 启动一个带有 couchdb 服务的网络环境。

docker-compose-2orgs-4peers-event.yaml: 启动一个带有 event 事件服务的网络环境。

scripts/: 存放用于安装、启动和测试的脚本

setup_Docker.sh: 安装并配置 dokcer 和 docker-compose。

download_images.sh: 下载相关镜像。

start_fabric.sh: 使用脚本快速启动一个最小环境。

initialize.sh: 自动化测试脚本，用来初始化 channel 和 chaincode。

test_4peers.sh: 自动化测试脚本，用来执行 chaincode 操作。

cleanup_env.sh: 容器，镜像自动清除脚本。

test_1peer.sh: 测试1个peer网络的自动化脚本。

e2e_cli/: 存放配置文件和证书。

channel-artifacts: 存放创建 orderer, channel, anchor peer 操作时的配置文件。

crypto-config: 存放 orderer 和 peer 相关证书。

example: 用来测试的 chaincode。

kafka/: 基于kafka 的 ordering 服务。

安装 Docker 和 docker-compose
docker 及 docker-compose 可以自行手动安装。也可以通过 hyperledger/1.0/scripts 提供的 setup_Docker.sh 脚本自动安装。

$ bash scripts/setup_Docker.sh
获取 Docker 镜像
Docker 镜像可以自行从源码编译，或从社区 DockerHub 仓库下载。通过 hyperledger/1.0/scripts 提供的 download_images.sh 脚本获取。

启动 fabric 1.0 网络
通过如下命令快速启动。

$ bash scripts/start_fabric.sh
或者

$ docker-compose -f docker-compose-2orgs-4peers.yaml up
注意输出日志中无错误信息。

此时，系统中包括 7 个容器。

$ docker ps -a
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS                                                                                 NAMES
8683435422ca        hyperledger/fabric-peer      "bash -c 'while true;"   19 seconds ago      Up 18 seconds       7050-7059/tcp                                                                         fabric-cli
f284c4dd26a0        hyperledger/fabric-peer      "peer node start --pe"   22 seconds ago      Up 19 seconds       7050/tcp, 0.0.0.0:7051->7051/tcp, 7052/tcp, 7054-7059/tcp, 0.0.0.0:7053->7053/tcp     peer0.org1.example.com
95fa3614f82c        hyperledger/fabric-ca        "fabric-ca-server sta"   22 seconds ago      Up 19 seconds       0.0.0.0:7054->7054/tcp                                                                fabric-ca
833ca0d8cf41        hyperledger/fabric-orderer   "orderer"                22 seconds ago      Up 19 seconds       0.0.0.0:7050->7050/tcp                                                                orderer.example.com
cd21cfff8298        hyperledger/fabric-peer      "peer node start --pe"   22 seconds ago      Up 20 seconds       7050/tcp, 7052/tcp, 7054-7059/tcp, 0.0.0.0:9051->7051/tcp, 0.0.0.0:9053->7053/tcp     peer0.org2.example.com
372b583b3059        hyperledger/fabric-peer      "peer node start --pe"   22 seconds ago      Up 20 seconds       7050/tcp, 7052/tcp, 7054-7059/tcp, 0.0.0.0:10051->7051/tcp, 0.0.0.0:10053->7053/tcp   peer1.org2.example.com
47ce30077276        hyperledger/fabric-peer      "peer node start --pe"   22 seconds ago      Up 20 seconds       7050/tcp, 7052/tcp, 7054-7059/tcp, 0.0.0.0:8051->7051/tcp, 0.0.0.0:8053->7053/tcp     peer1.org1.example.com
测试网络
启动 fabric 网络后，可以进行 chaincode 操作，验证网络是否启动正常。

进入到 cli 容器里面，执行 initialize.sh 和 test_4peers.sh 脚本。

通过如下命令进入容器 cli 并执行测试脚本。

$ docker exec -it fabric-cli bash
$ bash ./scripts/initialize.sh
注意输出日志无错误提示，最终返回结果应该为：

    UTC [main] main -> INFO 00c Exiting.....
    ===================== Chaincode Instantiation on PEER2 on channel 'businesschannel' is successful ===================== 


    ===================== All GOOD, initialization completed ===================== 


    _____   _   _   ____  
    | ____| | \ | | |  _ \ 
    |  _|   |  \| | | | | |
    | |___  | |\  | | |_| |
    |_____| |_| \_| |____/
之后同样是在 cli 容器里执行 test_4peers.sh 脚本

$ bash ./scripts/test_4peers.sh
    输出日志无错误提示，最终返回结果应该为：

    Query Result: 80
    UTC [main] main -> INFO 008 Exiting.....
    ===================== Query on PEER3 on channel 'businesschannel' is successful ===================== 

    ===================== All GOOD, End-2-End execution completed ===================== 


    _____   _   _   ____  
    | ____| | \ | | |  _ \ 
    |  _|   |  \| | | | | |
    | |___  | |\  | | |_| |
    |_____| |_| \_| |____/
至此，整个网络启动并验证成功。


三、具体手动测试 Fabric

在前面执行测试脚本的时候系统已经运行了一个 Example02 的 ChainCode 测试，部署上去的 ChainCodeName 是 mycc，所以接下来的测试不能再初始化并部署同样名字的 ChainCode 了，不过可以使用自己另外命名的名字，比如devin。

这里测试的内容主要是手动输入 Fabric 的命令如：
* install(载入 chaincode)
* instantiate(初始化 chaincode)
* query(查询)
* invoke(调动交易)

首先需要登录到 CLI 这个容器中，才能执行 Fabric 的 CLI 命令。

    docker exec -it cli bash

如果成功进入，我们会切换到该容器的root用户下，显示进入如下的命令行目录：

    root@12f2eb6d9fa6:/opt/gopath/src/github.com/hyperledger/fabric/peer#

与 Fabric 0.6 不同的是，在 1.0 中，链上代码是需要经过 Install 和 Instantiate 两步的。下面首先安装 Example02，并指定一个名字，比如这里就采用 devincc：
    
    peer chaincode install -n devincc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02

运行后可以看到提示运行成功，返回 200 状态；

接下来是 Instantiate，也就是初始化实例，设置 a 账户有 100 元，b 账户有 200 元。
    
    peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ca.example.com-cert.pem -C mychannel -n devincc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"


用 Query 命令来看一看a账户的余额：
    
    peer chaincode query -C mychannel -n devincc -c '{"Args":["query","a"]}'

接下来把 a 账户的 10 元转给 b 账户，需要调用 invoke 命令：
    
    peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ca.example.com-cert.pem  -C mychannel -n devincc -c '{"Args":["invoke","a","b","10"]}'

最后再调用query命令来查一下b账户的余额，应该是210元。

    peer chaincode query -C mychannel -n devincc -c '{"Args":["query","b"]}'


### 总结：
通过以上的步骤，我们成功部署并测试通过了 Fabric 1.0 Beta。至此应用的基础环境已经基本完成，同时也通过一些命令行的操作熟悉了 fabric 的底层交互逻辑。