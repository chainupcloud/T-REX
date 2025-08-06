// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@onchain-id/solidity/contracts/Identity.sol";
import "@onchain-id/solidity/contracts/ClaimIssuer.sol";
import "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
//import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
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
import "contracts/factory/ITREXFactory.sol";
import "contracts/compliance/legacy/DefaultCompliance.sol";
import "contracts/roles/permissioning/agent/AgentManager.sol";

import "contracts/proxy/ClaimTopicsRegistryProxy.sol";
import "contracts/proxy/TrustedIssuersRegistryProxy.sol";
import "contracts/proxy/IdentityRegistryStorageProxy.sol";
import "contracts/proxy/IdentityRegistryProxy.sol";
import "contracts/proxy/TokenProxy.sol";

import "contracts/factory/IdFactory.sol";

// FOUNDRY_PROFILE=tokenImpl forge script scripts/mainnet/TREXFactoryDeploy.s.sol:DeployTokenImpl --rpc-url $RPC_URL --broadcast --retries 10 --delay 30 --verify --etherscan-api-key $ETHERSCAN_API_KEY
contract DeployTokenImpl is Script {
    Token tokenImplementation;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        tokenImplementation = new Token();
        console.log("tokenImplementation:", address(tokenImplementation));

        vm.stopBroadcast();
    }
}

// forge script scripts/mainnet/TREXFactoryDeploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --retries 10 --delay 30 --verify --etherscan-api-key $ETHERSCAN_API_KEY
contract DeployScript is Script {
    address AddressZero = address(0);

    // modify
    address deployer = 0x0000000000000000000000000000000000000000;
    Token tokenImplementation = Token(0x0000000000000000000000000000000000000000);

    TREXImplementationAuthority trexImplementationAuthority;
    ClaimTopicsRegistry claimTopicsRegistryImplementation;
    TrustedIssuersRegistry trustedIssuersRegistryImplementation;
    IdentityRegistryStorage identityRegistryStorageImplementation;
    IdentityRegistry identityRegistryImplementation;
    ModularCompliance modularComplianceImplementation;

    Identity identityImplementation;
    ImplementationAuthority identityImplementationAuthority;

    IdFactory identityFactory;
    TREXFactory trexFactory;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署代理的实现合约
        claimTopicsRegistryImplementation = new ClaimTopicsRegistry();
        trustedIssuersRegistryImplementation = new TrustedIssuersRegistry();
        identityRegistryStorageImplementation = new IdentityRegistryStorage();
        identityRegistryImplementation = new IdentityRegistry();
        modularComplianceImplementation = new ModularCompliance();

        console.log("deploy TREXFactory");
        console.log("claimTopicsRegistryImplementation:", address(claimTopicsRegistryImplementation));
        console.log("trustedIssuersRegistryImplementation:", address(trustedIssuersRegistryImplementation));
        console.log("identityRegistryStorageImplementation:", address(identityRegistryStorageImplementation));
        console.log("identityRegistryImplementation:", address(identityRegistryImplementation));
        console.log("modularComplianceImplementation:", address(modularComplianceImplementation));
        console.log("tokenImplementation:", address(tokenImplementation));

        // 管理代理的权限合约
        trexImplementationAuthority = new TREXImplementationAuthority(true, AddressZero, AddressZero);
        console.log("deploy trexImplementationAuthority ");
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
        console.log("trexImplementationAuthority addAndUseTREXVersion success.");

        // 部署身份工厂合约
        identityImplementation = new Identity(deployer, true);
        identityImplementationAuthority = new ImplementationAuthority(address(identityImplementation));
        identityFactory = new IdFactory(address(identityImplementationAuthority));
        console.log("deploy IdFactory");
        console.log("identityImplementation:", address(identityImplementation));
        console.log("identityImplementationAuthority:", address(identityImplementationAuthority));
        console.log("identityFactory:", address(identityFactory));

        console.log("deploy TREXFactory");
        trexFactory = new TREXFactory(address(trexImplementationAuthority), address(identityFactory));
        console.log("trexFactory:", address(trexFactory));

        trexImplementationAuthority.setTREXFactory(address(trexFactory));
        console.log("trexImplementationAuthority setTREXFactory success.");
        trexImplementationAuthority.setIAFactory(address(identityFactory));
        console.log("trexImplementationAuthority setIAFactory success.");

        // identityFactory addTokenFactory
        identityFactory.addTokenFactory(address(trexFactory));
        console.log("identityFactory addTokenFactory success.");

        vm.stopBroadcast();
    }
}

// no need
// forge script scripts/mainnet/TREXFactoryDeploy.s.sol:DeployIdFactory --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --etherscan-api-key $ETHERSCAN_API_KEY
//contract DeployIdFactory is Script {
//
//    IdFactory identityFactory;
//
//    // --- modify -------
//    address identityImplementationAuthority = 0x0000000000000000000000000000000000000000;
//    TREXImplementationAuthority trexImplementationAuthority = TREXImplementationAuthority(0x0000000000000000000000000000000000000000);
//    TREXFactory trexFactory = TREXFactory(0x0000000000000000000000000000000000000000);
//    // ------------------------
//
//    function run() public {
//        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//        vm.startBroadcast(deployerPrivateKey);
//
//        identityFactory = new IdFactory(address(identityImplementationAuthority));
//        console.log("identityFactory:", address(identityFactory));
//
//        trexImplementationAuthority.setIAFactory(address(identityFactory));
//        identityFactory.addTokenFactory(address(trexFactory));
//        trexFactory.setIdFactory(address(identityFactory));
//
//        vm.stopBroadcast();
//    }
//
//}
