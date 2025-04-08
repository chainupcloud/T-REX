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

// token 合约 超过大小限制 无法部署 Error: `Token` is above the contract size limit (26700 > 24576).
// # 修改 foundry.toml
// optimizer_runs = 4_294_967_295
// 部署时指定 profile tokenImpl
// FOUNDRY_PROFILE=tokenImpl forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployTokenImpl --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
// 这种方式部署 在blockscout没有直接验证成功  需要手动再进行认证
// forge verify-contract 0xfb3De75b213cf204613b39f6aD1725773Bfc1b72 Token --chain 17000  --watch --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
contract DeployTokenImpl is Script {
    Token tokenImplementation;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        tokenImplementation = new Token();
        console.log("tokenImplementation:", address(tokenImplementation));

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployIdFactory --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
contract DeployIdFactory is Script {

    IdFactory identityFactory;

    address identityImplementationAuthority = 0xf9D6c5cd2e7B9c463Bdcdf6aE019AA1C69E7e723;
    TREXImplementationAuthority trexImplementationAuthority = TREXImplementationAuthority(0x53D5FECf18632fce03B93Bd435fA44fF4204dFE5);
    TREXFactory trexFactory = TREXFactory(0xc4e53CC5625a689938aD10726118db9D2dF84926);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        identityFactory = new IdFactory(address(identityImplementationAuthority));
        console.log("identityFactory:", address(identityFactory));

        trexImplementationAuthority.setIAFactory(address(identityFactory));
        identityFactory.addTokenFactory(address(trexFactory));
        trexFactory.setIdFactory(address(identityFactory));

        vm.stopBroadcast();
    }

}

// forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify
// forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
contract DeployScript is Script {
    address deployer = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
    address AddressZero = address(0);

    Token tokenImplementation = Token(0xfb3De75b213cf204613b39f6aD1725773Bfc1b72);

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
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
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

// forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployTokenByFactory --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify
// forge script scripts/testnet/TREXFactoryDeploy.s.sol:DeployTokenByFactory --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
contract DeployTokenByFactory is Script {
    address deployer = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
    address AddressZero = address(0);

    // 使用已部署的TokenFactory 实时修改
    TREXFactory trexFactory = TREXFactory(0x154C5e64de46EAe27342D9851Fd819DFC085d286);
    address identityRegistryStorageAddress = 0x0000000000000000000000000000000000000000;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        // 部署Token 参数定义
        string memory _salt = "token-uuid-1";

        address[] memory irAgents = new address[](2);
        irAgents[0] = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
        irAgents[1] = 0xe583DC38863aB4b5A94da77A6628e2119eaD4B18;
        address[] memory tokenAgents = new address[](2);
        tokenAgents[0] = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
        tokenAgents[1] = 0xe583DC38863aB4b5A94da77A6628e2119eaD4B18;
        address[] memory complianceModules = new address[](1);
        complianceModules[0] = 0xd9b7d77Be3b2d58f8d2cD39099a7779Fb6C5f4BC;
        bytes[] memory complianceSettings = new bytes[](0);
        ITREXFactory.TokenDetails memory _tokenDetails = ITREXFactory.TokenDetails({
            owner: deployer,
            name: "TREX Token",
            symbol: "TREX",
            decimals: 18,
            irs: identityRegistryStorageAddress,
            ONCHAINID: AddressZero,
            irAgents: irAgents,
            tokenAgents: tokenAgents,
            complianceModules: complianceModules,
            complianceSettings: complianceSettings
        });

        ITREXFactory.ClaimDetails memory _claimDetails = ITREXFactory.ClaimDetails({
            claimTopics: new uint256[](0),
            issuers: new address[](0),
            issuerClaims: new uint256[][](0)
        });

        // auth owner
        trexFactory.deployTREXSuite(_salt, _tokenDetails, _claimDetails);

        vm.stopBroadcast();
    }
}
