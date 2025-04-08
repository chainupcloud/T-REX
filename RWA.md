# rwa-contracts

RWA 多链智能合约

> 各仓库为github引用，多仓库提交到stash。

# 简介

## 项目简介

- T-REX ERC3643合约实现  对应版本：v4.1.6
- CMTAT CMTAT 核心合约实现 对应版本：v2.3.0
- RuleEngine CMTAT 规则引擎合约实现 对应版本：v1.0.2.1


# 合约修改

1. 修改 TREX 的 TREXFactory 合约的 deployTREXSuite 方法，去掉 onlyOwner 的约束。方便由任意地址去部署 ERC3643的Token。
2. 移除 IdFactory 合约，createIdentity 和 createIdentityWithManagementKeys 方法的onlyOwner 的约束。 方便任意地址创建身份。
