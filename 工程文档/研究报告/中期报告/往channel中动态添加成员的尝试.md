# 往channel中动态添加成员的尝试

## 静态官方 demo
### 生成证书, 密钥, 配置文件等信息

    byfn.sh -m generate

#### 生成证书, 密钥

    cryptogen generate --config=./crypto-config.yaml

#### 生成创世块  

    export FABRIC_CFG_PATH=$PWD
    ../bin/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

#### 生成 channel 的配置信息

    export CHANNEL_NAME=mychannel
    ../bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

#### 在 Org1MSPanchors.tx 中写入 org1 的 anchor peer 的配置信息

    ../bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

#### 在 Org2MSPanchors.tx 中写入 org2 的 anchor peer 的配置信息

    ../bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

### 拉起网络, 创建容器

    CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=60 docker-compose -f docker-compose-cli.yaml up -d

### 进入 cli 容器

    docker exec -it cli bash

### 根据刚刚生成的 channel.tx 来创建 channel

    export CHANNEL_NAME=mychannel
    peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

实际上是向 orderer 发送一个创建 channel 的 transaction,orderer 检查发送者的证书以及 channel 的合理性, 使用了 tls 传输层安全协议, 指定 orderer 的传输层安全协议证书

结果: 在当前目录下生成 mychannel.block

### 把 peer 加入 channel 中

    peer channel join -b mychannel.block

### 在 peer 上安装 chaincode

    peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02

### 在 peer 上实例化 chaincode


    peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"


### 执行事务

    peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'

---

## 静态任意多节点 demo

### 删除证书密钥, 删除中间生成的 genesis.block,channel.tx,Org1MSP,Org2MSP 等, 删除容器

    byfn.sh -m down

修改 crypto-config.yaml 文件
在 peerOrgs 中添加 Org3

修改 config.yaml 文件
在 profile 中添加 org3
在 organization 中添加 org3

修改 base/docker-compose-base.yaml
增加 peer0.org3.example.com services

修改 docker-compose-cli.yaml
增加 peer0.org3.example.com services
增加 org3.example.com depends_on

剩余执行与上面一致的步骤

---

## 证明无法 ** 通过修改上面四个配置文件 ** 达到动态添加成员的目的
### 证明 1: 无法动态添加 peer
执行完官方 demo 之后生成了 Fabric 网络, 现在要往里面再添加 peer,
#### 尝试 1: 使用同一 Org 下的其他 peer 的证书和密钥
新建一个 peer2.org1.example.com 文件夹, 复制 peer0 的证书密钥文件到该文件夹.
![change-peer0-to-peer1.png](https://i.loli.net/2017/08/14/5990fa4761c09.png)

在 docker-compose-cli.yaml 和 docker-compose-base.yaml 中添加该 peer2 的 services, 启动网络, ls 发现 mychannel.block 还在, 设置环境变量指向该 peer, 将该 peer 加入 channel, 提示证书对 peer0.org1.example.com 有效, 对 peer1.org1.example.com 无效

![certificate-invalid.png](https://i.loli.net/2017/08/14/5990fa8e6a50d.png)
#### 尝试 2: 为该 peer 用 cryptogen 工具生成自己的证书
需要修改 crypto-config.yaml

    PeerOrgs:
      - Name: Org1
      Domain: org1.example.com
      Template:
        Count: 1
        Start: 0
        User:
        Count: 1

结构如上, Template 的 Count 代表了 peer 的数量, start 表示 peer 的 identity 的开始位移
所以只需要修改 Template 的 Count 为 2 即可, 使用 cryptogen generate --config=./crypto-config.yaml 生成所需证书, 观察到 crypto-config.yaml 中有 orderer,org1 和 org2, 需要指出的是, 如果没有把 orderer 部分和 org2 部分注释掉的话, oederer 和 org2 的证书会重新生成, 此时 mychannel.block 还在, 执行 query 失败, peer0.org.example.com(即一开始就在 channel 中的另外一个 org 的 peer) 试图通过 mychannel.block 加入 channel 失败, 提示验证 tlsca.org2.example.com 证书 (tlsca.org2.example.com 证书) 时失败. 由此可知, mychannel.block 是与 org(包括 ordererOrg) 的证书绑定在一起的, 证书更新时, mychannel 也需要更新.
![count=2-in-org1.png](https://i.loli.net/2017/08/14/5990fcb20d6bd.png)

尝试 3:
如果注释掉 crypto-config.yaml 中的 orderer 和 org2, 只留下 org1(因为要添加的 peer 是 peer1.org1.example.com), 将 Count: 1 修改为 2 之后, 该 Org 的证书以及 peer0.org1.example.com 的证书全部重新生成, 并且宣告旧的证书作废 (但仍保留在文件夹中).
由于是添加已有组织的 peer 节点, 我们查看 config.yaml 发现只与 org 有关, 与 org 旗下下面的 peer 无关, 因此不需要修改 config.yaml, 而之前生成的 genesis.block 和 channel.tx 也可以继续使用
重新生成包含 anchor 的 Org1MSP

    ../bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

docker-compose -f docker-compose-cli.yaml up 拉起网络 ls
![peer1-org1-ls-still.png](https://i.loli.net/2017/08/14/5990fd8760e99.png)
看到之前生成的 mychannel.block 还在, 执行 query 命令看一下之前搭建好的 Fabric 网络已经无法正常运行了, 将环境变量切换到 peer0.org2.example.com, 通过 mychannel.block 成功 join, 运行 query 也能成功查询到结果.
在静态 demo 的 4 个 peer 中搭建好 fabric 网络后, org 和 order 证书都没有变化, 所以所有 peer 都能够通过 mychannel.block 加入到 channel 中
在上次尝试中, orderer 和 org 的证书都变了, peer1.org1.example 无法加入 channel 中, peer0.org1.example.com 也无法查询到
在本次尝试中只有 org1 的证书变了, 结果是 org1 无法查询到 channel 中 (或者说是 ledger 中) 的数据, 也无法加入, 而 org2 证书没有变化, 可以通过 mychannel.block 加入到 channel 中, 也可以查询到数据.
由此我们可以得出结论: 更新了证书之后一定要更新 mychannel.block

#### 与 orderer 证书无关
搭建好 Fabric 网络后, 注释掉 Org1 和 Org2, 只生成 orderer 的新证书, 进入 cli 容器中仍旧可以查询, 加入 peer,install chaincode 等操作.
#### 尝试 3: 更新 channel 信息

    peer channel update

### 添加 org3
在 ** 搭建好 ** Fabric 网络之后
修改 crypto-config.yaml
注释掉其他 org, 增加 org3
![org3-crypto-config-yaml.png](https://i.loli.net/2017/08/14/5991019376aba.png)
修改 config.yaml
增加 org3
![org3-config-yaml.png](https://i.loli.net/2017/08/14/5991012e9a17e.png)
![org3-service-config-yaml.png](https://i.loli.net/2017/08/14/59910148efd9b.png)
修改 docker-compose-cli.yaml
增加 org3 的 services
![peer1-org1-in-cli-yaml.png](https://i.loli.net/2017/08/14/5990fea32a706.png)
修改 docker-compose-base.yaml
增加 org3 的 services
![peer1-org1-in-base-yaml.png](https://i.loli.net/2017/08/14/5990fe8298d97.png)
使用 cryptogen 生成 org3 的证书密钥, 更新创世块和 channel.tx, 更新 OrgMSP,docker-compose docker-compose-cli.yaml up 拉起网络
![Screenshot from 2017-08-08 19-01-44.png](https://i.loli.net/2017/08/14/59910460bf693.png)
ls 看到 mychannel.block 已经不在了, 先执行 query 查询确认 fabric 网络仍正常运行
![Screenshot from 2017-08-08 19-08-01.png](https://i.loli.net/2017/08/14/599102fce4548.png)
试图通过 peer0.org3.example.com 来创建 channel 以生成 channel.block, 然后再通过这个 block 加入 channel, 但是将环境变量切换到 peer0.org3.example.com 后 create 失败
![Screenshot from 2017-08-08 19-10-16.png](https://i.loli.net/2017/08/14/5991054905366.png)
查看日志, 检测到 version 为 1, 期望值为 0, 即表示检测到已经安装了
![Screenshot from 2017-08-08 19-14-05.png](https://i.loli.net/2017/08/14/5991056722932.png)
更新 channel
peer channel update -f new_channel.tx -c $CHANNEL_NAME -o 127.0.0.1:7050
update 失败, 提示

    grpc: addrConn.resetTransport failed to create client transport: connection error: desc = "transport: Error while dialing dial tcp 127.0.0.1:7050: getsockopt: connection refused"; Reconnecting to {127.0.0.1:7050 <nil>}
    Error: Error connecting due to  rpc error: code = Unavailable desc = grpc: the connection is unavailable

![update-unavailable.png](https://i.loli.net/2017/08/14/5990ff3173f36.png)

docker logs orderer.example.com 查看日志, 提示

    grpc: Server.Serve failed to complete security handshake from "172.23.0.5:52752": tls: first record does not look like a TLS handshake

![record-not-like-TLS-handshake.png](https://i.loli.net/2017/08/14/5990ff721774e.png)

---
## configtxlator 工具
### 简介
configtxlator 工具是用于独立于 SDK 进行 reconfiguration, channel 的 configuration 作为 transaction 被存储在 channel 的配置块中, 可用于直接操作如 bdd 行为测试, 然而, 在撰写本文时, 没有 SDK 本身支持直接操作 configuration, 因此 configtxlator 工具被设计用来提供与 configuration 交互协助更写的 API 接口给 SDK 使用者
这个工具名称是 config 和 translator 和混合词, 旨在表明该工具仅仅在不同的等价数据表示之间进行转换. 它不生成配置, 不提交或恢复配置, 它不会修改配置本身, 它只是在 configtx 生成物的不同视图之间提供一些双向操作.

这个工具的期望标准用法是:
  * SDK 恢复最近的 config
  * 提供便于人类阅读的 config 版本
  * 用户或应用程序编辑 config
  * 用于计算以变化为表示形式的 config 更新
  * SDK 提交签名和 config

configtxlator 工具公开可信任无状态的 REST API 接口, 用于与 configuration 元素交互, 这些 REST 组件支持将原生的 configuration 格式转化为便于人类阅读的 JSON 格式文件 (或将 JSON 转化为 configuration 格式的二进制文件), 同时根据两个不同的 configuration 的不同计算 configuration 的更新.
因为 configtxlator 服务故意不包含任何加密资料或其他秘密信息, 它不包括任何授权或访问控制. 预期的典型部署将是在本地与应用程序一起作为沙盒容器运行, 以便为每个消费者提供专用的配置程序.
configtxlator 工具可以与其他 Hyperledger Fabric 平台特定的二进制文件一起下载. 有关详细信息, 请参阅特定于下载平台的二进制文件.
### 用法
该工具可能被配置为侦听不同的端口, 您也可以使用 --port 和 --hostname 标志来指定主机名. 要查看完整的命令和标志, 请运行 configtxlator --help
二进制文件将启动在指定端口上侦听的 http 服务器之后可以处理请求.
#### 启动 configtxlaor 服务:

    configtxlator start

对于可扩展性, 并且由于某些字段必须签名, 许多 proto 字段将以字节存储. 这导致使用 jsonpb 工具包将原始的 proto 转化为 JSON 以产生人类可阅读的 protobuf 版本效率低下. 相反, configtxlator 工具公开的 REST 组件可以执行更复杂的翻译.
#### decode
为了将 proto 转化为等价的人类可阅读的 JSON, 只需简单地将二进制的 proto post 到下面这个地址 http://\$SERVER:\$PORT/protolator/decode/<message.Name>, 这里的 message.Name 是 proto 的完全限定名称 (fully qualified name of the message).
例如: 要解码保存为 configuration_block.pb 的配置块, 请运行以下命令:

    curl -X POST --data-binary @configuration_block.pb http://127.0.0.1:7059/protolator/decode/common.Block

#### encode
要转换原始消息的人类可读的 JSON 版本，只需将 JSON 版本 post 到 http://\$SERVER:\$PORT/protolator/encode/<message.Name>
例如: 想要重新编码保存为 configuration_block.json 的块, 运行命令:

    curl -X POST --data-binary @configuration_block.json http://127.0.0.1:7059/protolator/encode/common.Block

任何与 configuration 相关的 protos, 包括 common.Block,common.Envelope,common.ConfigEnvelope,common.ConfigUpdateEnvelope,common.Config 和 common.ConfigUpdate 都是这些 URL 的有效目标. 将来可能会添加其他原型解码类型, 例如用于代理交易.
#### Config update computation
给定两种不同的 configuration, 可以计算它们之间转换的 configuration 更新. 只需将两个 encode configuration 为 multipart/formdata 的 common.Config proto post 到 http://\$SERVER:\$PORT/configtxlator/compute/update-from-configs
例如, 在通道名为 desiredchannel 的 channel 中, 将原始配置作为 original_config.pb 文件和更新后的配置作为 updated_config.pb 文件：

    curl -X POST -F channel=desiredchannel -F original=@original_config.pb -F updated=@updated_config.pb http://127.0.0.1:7059/configtxlator/compute/update-from-configs

#### work flow
1. configtxlator start
2. produce a genesis.block for orderer system channel
3. decode the genesis block into a human editable form
4. Edit the genesis_block.json file
5. re-encoded into the native proto form--generate the new genesis block

#### example:
启动 orderer:

    ORDERER_GENERAL_LOGLEVEL=debug orderer

从 channel 中获取 config_block proto:

    peer channel fetch config config_block.pb -o 127.0.0.1:7050 -c testchainid

把 config block 传给 configtxlator 解码:

    curl -X POST --data-binary @config_block.pb http://127.0.0.1:7059/protolator/decode/common.Block > config_block.json

从 config block 中提取 config 部分:

    jq .data.data[0].payload.data.config config_block.json > config.json

编辑 config, 另存为新的 updated_config.json:

    jq ".channel_group.groups.Orderer.values.BatchSize.value.max_message_count = 30" config.json  > updated_config.json

对原来的 config 和新 config 进行重新编码成 proto:

    curl -X POST --data-binary @config.json http://127.0.0.1:7059/protolator/encode/common.Config > config.pb
    curl -X POST --data-binary @updated_config.json http://127.0.0.1:7059/protolator/encode/common.Config > updated_config.pb

计算两个 config 之间的更新:

    curl -X POST -F original=@config.pb -F updated=@updated_config.pb http://127.0.0.1:7059/configtxlator/compute/update-from-configs -F channel=testchainid > config_update.pb

At this point, the computed config update is now prepared. Traditionally, an SDK would be used to sign and wrap this message. However, in the interest of using only the peer cli, the configtxlator can also be used for this task.
we decode the ConfigUpdate so that we may work with it as text:

    curl -X POST --data-binary @config_update.pb http://127.0.0.1:7059/protolator/decode/common.ConfigUpdate > config_update.json

打包成 envelope message:

    echo '{"payload":{"header":{"channel_header":{"channel_id":"testchainid","type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' > config_update_as_envelope.json

转化成完整的 proto 形式:

    curl -X POST --data-binary @config_update_as_envelope.json http://127.0.0.1:7059/protolator/encode/common.Envelope > config_update_as_envelope.pb

提交更新后的 config 给 orderer 以更新信息:

    peer channel update -f config_update_as_envelope.pb -c testchainid -o 127.0.0.1:7050

![work-flow.png](https://i.loli.net/2017/08/14/59910eb4dac12.png)
![update-error.png](https://i.loli.net/2017/08/14/5991069187e2b.png)

---

    root# export FABRIC_CFG=$PWD

    root# ./peer channel fetch config config_block.pb -o 127.0.0.1:7050 -c testchainid

    2017-08-14 10:50:27.983 CST [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
    2017-08-14 10:50:27.999 CST [main] main -> INFO 002 Exiting.....

    root# curl -X POST --data-binary @config_block.pb http://127.0.0.1:7059/protolator/decode/common.Block > config_block.json

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100 18688    0 12461  100  6227   306k   153k --:--:-- --:--:-- --:--:--  312k

    root# jq .data.data[0].payload.data.config config_block.json > config.json

    root# jq ".channel_group.groups.Orderer.values.BatchSize.value.max_message_count = 30" config.json  > updated_config.json

    root# jq ".channel_group.groups.Orderer.values.BatchSize.value.max_message_count = 40" config.json  > updated_config.json

    root# curl -X POST --data-binary @config.json http://127.0.0.1:7059/protolator/encode/common.Config > config.pb

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100  4405  100   773  100  3632   532k  2501k --:--:-- --:--:-- --:--:-- 3546k

    root# curl -X POST --data-binary @updated_config.json http://127.0.0.1:7059/protolator/encode/common.Config > updated_config.pb

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100  4405  100   773  100  3632   555k  2611k --:--:-- --:--:-- --:--:-- 3546k

    root# curl -X POST -F original=@config.pb -F updated=@updated_config.pb http://127.0.0.1:7059/configtxlator/compute/update-from-configs -F channel=testchainid > config_update.pb

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100  2105  100    81  100  2024   2071  51750 --:--:-- --:--:-- --:--:-- 51897

    root# curl -X POST --data-binary @config_update.pb http://127.0.0.1:7059/protolator/decode/common.ConfigUpdate > config_update.json

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100   461  100   380  100    81   417k  91216 --:--:-- --:--:-- --:--:--  371k

    root# echo '{"payload":{"header":{"channel_header":{"channel_id":"testchainid","type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' > config_update_as_envelope.json

    root# curl -X POST --data-binary @config_update_as_envelope.json http://127.0.0.1:7059/protolator/encode/common.Envelope > config_update_as_envelope.pb

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 -100   506  100   106  100   400   127k   481k --:--:-- --:--:-- --:--:--  390k

    root# ./peer channel update -f config_update_as_envelope.pb -c testchainid -o 127.0.0.1:7050

    2017-08-14 10:53:55.495 CST [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
    2017-08-14 10:53:55.497 CST [main] main -> INFO 002 Exiting.....
![difference.png](https://i.loli.net/2017/08/14/5991173abae9d.png)
再次 fetch 查看
![fetch-change.png](https://i.loli.net/2017/08/14/5991187295005.png)
![fetch-difference.png](https://i.loli.net/2017/08/14/5991186bc7f2f.png)
确实改变了值, 签名, metadata 和 timestamp 都更新了

实战:
首先搭建好 fabric 网络
configtxlator start
peer channel fetch config config_block.pb -o 127.0.0.1:7050 -c mychannel
错误
![get-mychannel-block-error.png](https://i.loli.net/2017/08/14/59911bbc0f5e0.png)
查看 log 信息
![log-orderer.png](https://i.loli.net/2017/08/14/59911cc8c75ba.png)
无法获得 channel 的 config 信息
peer channel fetch config config.block -o 127.0.0.1:7050 -c mychannel
![error-config-block.png](https://i.loli.net/2017/08/14/59911c9dbb527.png)
以上两个错误都是同一种错误
从 mychannel.block 入手
![config-json.png](https://i.loli.net/2017/08/14/599161c3b437e.png)
只需要在 groups 下增加 org3MSP, 但重点在于 admins,root_certs,tls_root_certs 的取值, 目测是加密之后的结果, 试图将它与 Org1MSPanchors.tx,Org2MSPanchors.tx 联系起来, 将 Org1MSPanchors.tx 解码

    curl -X POST --data-binary @Org1MSPanchors.tx http://127.0.0.1:7059/protolator/decode/common.Block > msp1.json

但无法解码, msp1.json 内容为 proto: bad wiretype for field common.BlockHeader.Number: got wiretype 2, want 0
相信只要能够找到admins,root_certs,tls_root_certs下的取值,应该就可以将组织或peer加进已有的channel中
