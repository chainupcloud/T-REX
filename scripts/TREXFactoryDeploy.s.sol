// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@onchain-id/solidity/contracts/Identity.sol";
import "@onchain-id/solidity/contracts/ClaimIssuer.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/proxy/IdentityProxy.sol";
import "@onchain-id/solidity/contracts/storage/Structs.sol";

import "contracts/registry/implementation/ClaimTopicsRegistry.sol";
import "contracts/registry/implementation/TrustedIssuersRegistry.sol";
import "contracts/registry/implementation/IdentityRegistryStorage.sol";
import "contracts/registry/implementation/IdentityRegistry.sol";
import "contracts/compliance/modular/ModularCompliance.sol";
import "contracts/token/Token.sol";
import "contracts/proxy/authority/TREXImplementationAuthority.sol";
import "contracts/proxy/authority/ITREXImplementationAuthority.sol";
import "contracts/factory/TREXFactory.sol";
import "contracts/compliance/legacy/DefaultCompliance.sol";
import "contracts/roles/permissioning/agent/AgentManager.sol";

import "contracts/proxy/ClaimTopicsRegistryProxy.sol";
import "contracts/proxy/TrustedIssuersRegistryProxy.sol";
import "contracts/proxy/IdentityRegistryStorageProxy.sol";
import "contracts/proxy/IdentityRegistryProxy.sol";
import "contracts/proxy/TokenProxy.sol";

// forge script contracts/factory/TREXFactory.sol:DeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify
contract DeployScript is Script {
    address deployer = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
    address AddressZero = address(0);

    TREXImplementationAuthority trexImplementationAuthority;
    ClaimTopicsRegistry claimTopicsRegistryImplementation;
    TrustedIssuersRegistry trustedIssuersRegistryImplementation;
    IdentityRegistryStorage identityRegistryStorageImplementation;
    IdentityRegistry identityRegistryImplementation;
    ModularCompliance modularComplianceImplementation;
    Token tokenImplementation;

    Identity identityImplementation;
    ImplementationAuthority identityImplementationAuthority;
    IdFactory identityFactory;

    IdFactory identityFactory;
    TREXFactory trexFactory;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        // 部署代理的实现合约
        claimTopicsRegistryImplementation = new ClaimTopicsRegistry();
        trustedIssuersRegistryImplementation = new TrustedIssuersRegistry();
        identityRegistryStorageImplementation = new IdentityRegistryStorage();
        identityRegistryImplementation = new IdentityRegistry();
        modularComplianceImplementation = new ModularCompliance();
        tokenImplementation = new Token();

        console.log("=== 部署TREXFactory 依赖的逻辑合约 ====");
        console.log("claimTopicsRegistryImplementation:", address(claimTopicsRegistryImplementation));
        console.log("trustedIssuersRegistryImplementation:", address(trustedIssuersRegistryImplementation));
        console.log("identityRegistryStorageImplementation:", address(identityRegistryStorageImplementation));
        console.log("identityRegistryImplementation:", address(identityRegistryImplementation));
        console.log("modularComplianceImplementation:", address(modularComplianceImplementation));
        console.log("tokenImplementation:", address(tokenImplementation));

        // 管理代理的权限合约
        trexImplementationAuthority = new TREXImplementationAuthority(true, AddressZero, AddressZero);
        console.log("=== 部署 逻辑合约的 管理合约 trexImplementationAuthority====");
        console.log("trexImplementationAuthority:", address(trexImplementationAuthority));

        // Version 使用代表 v1.0.0 对应Trex版本 v4.1.6
        ITREXImplementationAuthority.Version memory versionStruct = ITREXImplementationAuthority.Version(1, 0, 0);
        ITREXImplementationAuthority.TREXContracts memory contractsStruct = ITREXImplementationAuthority.TREXContracts({
            tokenImplementation: address(tokenImplementation),
            ctrImplementation: address(claimTopicsRegistryImplementation),
            irImplementation: address(identityRegistryImplementation),
            irsImplementation: address(identityRegistryStorageImplementation),
            tirImplementation: address(trustedIssuersRegistryImplementation),
            mcImplementation: address(modularComplianceImplementation)
        });

        trexImplementationAuthority.addAndUseTREXVersion(versionStruct, contractsStruct);
        console.log("=== trexImplementationAuthority addAndUseTREXVersion success.====");

        // 部署身份工厂合约
        identityImplementation = new Identity(deployer, true);
        identityImplementationAuthority = new ImplementationAuthority(address(identityImplementation));
        identityFactory = new IdFactory(address(identityImplementationAuthority));
        console.log("=== 部署 IdFactory ====");
        console.log("identityImplementation:", address(identityImplementation));
        console.log("identityImplementationAuthority:", address(identityImplementationAuthority));
        console.log("identityFactory:", address(identityFactory));

        console.log("=== 部署TREXFactory====");
        trexFactory = new TREXFactory(address(trexImplementationAuthority), address(identityFactory));
        console.log("trexFactory:", address(trexFactory));

        trexImplementationAuthority.setTREXFactory(address(trexFactory));
        console.log("=== trexImplementationAuthority setTREXFactory success.====");
        trexImplementationAuthority.setIAFactory(address(identityFactory));
        console.log("=== trexImplementationAuthority setIAFactory success.====");

        // identityFactory addTokenFactory
        identityFactory.addTokenFactory(address(trexFactory));
        console.log("=== identityFactory addTokenFactory success.====");

        vm.stopBroadcast();
    }
}


// forge script contracts/factory/TREXFactory.sol:DeployTokenByFactory --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify
contract DeployTokenByFactory is Script {
    address deployer = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    // 使用已部署的TokenFactory
    TREXFactory trexFactory = TREXFactory(0x0000000000000000000000000000000000000000);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        // auth owner
        trexFactory.deployTREXSuite();

        vm.stopBroadcast();
    }



}