// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

import "forge-std/Test.sol";

// forge test --match-path  test-forge/TREX.t.sol
// solhint-disable
contract TREXTest is Test {
    address AddressZero = address(0);

    // account
    address deployer = address(1);
    address tokenIssuer = address(2);
    address tokenAgent = address(3);
    address tokenAdmin = address(4);
    address claimIssuer = address(5);

    address claimIssuerSigningKeyAddress;
    address aliceActionKeyAddress;
    uint256 claimIssuerSigningKey;
    uint256 aliceActionKey;

    // user account
    address aliceWallet = address(101);
    address bobWallet = address(102);
    address charlieWallet = address(103);
    address davidWallet = address(104);
    address anotherWallet = address(105);

    bytes emptyBytes;

    // trex contracts
    ClaimTopicsRegistry claimTopicsRegistryImplementation;
    TrustedIssuersRegistry trustedIssuersRegistryImplementation;
    IdentityRegistryStorage identityRegistryStorageImplementation;
    IdentityRegistry identityRegistryImplementation;
    ModularCompliance modularComplianceImplementation;
    Token tokenImplementation;
    TREXImplementationAuthority trexImplementationAuthority;
    TREXFactory trexFactory;
    DefaultCompliance defaultCompliance;
    AgentManager agentManager;

    // proxy
    ClaimTopicsRegistryProxy claimTopicsRegistryProxy;
    TrustedIssuersRegistryProxy trustedIssuersRegistryProxy;
    IdentityRegistryStorageProxy identityRegistryStorageProxy;
    IdentityRegistryProxy identityRegistryProxy;
    TokenProxy token;

    // onChainID contract
    Identity identityImplementation;
    ImplementationAuthority identityImplementationAuthority;
    IdFactory identityFactory;
    IdentityProxy tokenOID;
    ClaimIssuer claimIssuerContract;

    // user onChainID
    IdentityProxy aliceIdentity;
    IdentityProxy bobIdentity;
    IdentityProxy charlieIdentity;

    function setUp() public {}

    /**
     * @dev Recovers the signer of a given hash and signature.
     * @param hash The hash that was signed.
     * @param signature The signature to verify.
     * @return address The address of the signer.
     */
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return ecrecover(hash, v, r, s);
    }

    function initFullTREXContracts() public {
        // ge pk. 生成两个私钥，用于后续的签名
        (claimIssuerSigningKeyAddress, claimIssuerSigningKey) = makeAddrAndKey("claimIssuerSigningKeyAddress");
        (aliceActionKeyAddress, aliceActionKey) = makeAddrAndKey("aliceActionKeyAddress");

        vm.startPrank(deployer);

        // new contracts 部署实现合约
        claimTopicsRegistryImplementation = new ClaimTopicsRegistry();
        trustedIssuersRegistryImplementation = new TrustedIssuersRegistry();
        identityRegistryStorageImplementation = new IdentityRegistryStorage();
        identityRegistryImplementation = new IdentityRegistry();
        modularComplianceImplementation = new ModularCompliance();
        tokenImplementation = new Token();

        // 部署默认的合约合约
        defaultCompliance = new DefaultCompliance();

        identityImplementation = new Identity(deployer, true);
        identityImplementationAuthority = new ImplementationAuthority(address(identityImplementation));
        identityFactory = new IdFactory(address(identityImplementationAuthority));

        // manager contract. 用于管理所有代理合约-逻辑合约的权限
        trexImplementationAuthority = new TREXImplementationAuthority(true, AddressZero, AddressZero);

        // 设置实现合约 为后续部署代理合约做准备
        ITREXImplementationAuthority.Version memory versionStruct = ITREXImplementationAuthority.Version(4, 0, 0);
        ITREXImplementationAuthority.TREXContracts memory contractsStruct = ITREXImplementationAuthority.TREXContracts({
            tokenImplementation: address(tokenImplementation),
            ctrImplementation: address(claimTopicsRegistryImplementation),
            irImplementation: address(identityRegistryImplementation),
            irsImplementation: address(identityRegistryStorageImplementation),
            tirImplementation: address(trustedIssuersRegistryImplementation),
            mcImplementation: address(modularComplianceImplementation)
        });
        // trexImplementationAuthority addAndUseTREXVersion
        trexImplementationAuthority.addAndUseTREXVersion(versionStruct, contractsStruct);

        trexFactory = new TREXFactory(address(trexImplementationAuthority), address(identityFactory));

        // identityFactory addTokenFactory
        identityFactory.addTokenFactory(address(trexFactory));

        // deploy for proxy use erc3643 `AbstractProxy.sol`
        // Using `trexImplementationAuthority` to control the addresses of multiple proxy contracts is more complex than uups
        claimTopicsRegistryProxy = new ClaimTopicsRegistryProxy(address(trexImplementationAuthority));
        trustedIssuersRegistryProxy = new TrustedIssuersRegistryProxy(address(trexImplementationAuthority));
        identityRegistryStorageProxy = new IdentityRegistryStorageProxy(address(trexImplementationAuthority));
        identityRegistryProxy = new IdentityRegistryProxy(
            address(trexImplementationAuthority),
            address(trustedIssuersRegistryProxy),
            address(claimTopicsRegistryProxy),
            address(identityRegistryStorageProxy)
        );

        // token contracts
        tokenOID = new IdentityProxy(address(identityImplementationAuthority), tokenIssuer);
        string memory tokenName = "TREXDINO";
        string memory tokenSymbol = "TREX";
        uint8 tokenDecimals = 18;
        token = new TokenProxy(
            address(trexImplementationAuthority),
            address(identityRegistryProxy),
            address(defaultCompliance),
            tokenName,
            tokenSymbol,
            tokenDecimals,
            address(tokenOID)
        );

        IdentityRegistryStorage(address(identityRegistryStorageProxy)).bindIdentityRegistry(
            address(identityRegistryProxy)
        );
        Token(address(token)).addAgent(tokenAgent);

        uint256 claimTopic = uint256(keccak256(abi.encodePacked("CLAIM_TOPIC")));
        ClaimTopicsRegistry(address(claimTopicsRegistryProxy)).addClaimTopic(claimTopic);

        vm.stopPrank();

        // agent
        vm.startPrank(tokenAgent);
        agentManager = new AgentManager(address(token));
        vm.stopPrank();

        // claimIssuer
        vm.startPrank(claimIssuer);
        claimIssuerContract = new ClaimIssuer(claimIssuer);
        claimIssuerContract.addKey(keccak256(abi.encode(claimIssuerSigningKeyAddress)), 3, 1);
        vm.stopPrank();

        vm.startPrank(deployer);
        uint256[] memory claimTopics = new uint256[](1);
        claimTopics[0] = claimTopic;
        TrustedIssuersRegistry(address(trustedIssuersRegistryProxy)).addTrustedIssuer(claimIssuerContract, claimTopics);

        // for user Identity
        aliceIdentity = new IdentityProxy(address(identityImplementationAuthority), aliceWallet);
        bobIdentity = new IdentityProxy(address(identityImplementationAuthority), bobWallet);
        charlieIdentity = new IdentityProxy(address(identityImplementationAuthority), charlieWallet);

        // IdentityRegistry set agent
        IdentityRegistry(address(identityRegistryProxy)).addAgent(tokenAgent);
        IdentityRegistry(address(identityRegistryProxy)).addAgent(address(token));

        vm.stopPrank();

        // alice Identity add key
        vm.prank(aliceWallet);
        Identity(address(aliceIdentity)).addKey(keccak256(abi.encode(aliceActionKeyAddress)), 2, 1);

        // Identity resister
        address[] memory _userAddresses = new address[](2);
        IIdentity[] memory _identities = new IIdentity[](2);
        uint16[] memory _countries = new uint16[](2);
        _userAddresses[0] = aliceWallet;
        _userAddresses[1] = bobWallet;
        _identities[0] = IIdentity(address(aliceIdentity));
        _identities[1] = IIdentity(address(bobIdentity));
        _countries[0] = 42;
        _countries[1] = 666;

        vm.prank(tokenAgent);
        IdentityRegistry(address(identityRegistryProxy)).batchRegisterIdentity(_userAddresses, _identities, _countries);

        // for alice claim and sign
        Structs.Claim memory claimForAlice = Structs.Claim({
            topic: claimTopic,
            scheme: 1,
            issuer: address(claimIssuerContract),
            signature: emptyBytes,
            data: abi.encodePacked("Some claim public data."),
            uri: ""
        });

        bytes32 claimForAliceSignHash =
            keccak256(abi.encode(address(aliceIdentity), claimForAlice.topic, claimForAlice.data));
        (uint8 vAlice, bytes32 rAlice, bytes32 sAlice) = vm.sign(claimIssuerSigningKey, claimForAliceSignHash);
        claimForAlice.signature = abi.encodePacked(rAlice, sAlice, vAlice);
        // todo verify signature

        // alice Identity add Claim
        vm.prank(aliceWallet);
        Identity(address(aliceIdentity)).addClaim(
            claimForAlice.topic,
            claimForAlice.scheme,
            claimForAlice.issuer,
            claimForAlice.signature,
            claimForAlice.data,
            claimForAlice.uri
        );

        // for bob claim and sign
        Structs.Claim memory claimForBob = Structs.Claim({
            topic: claimTopic,
            scheme: 1,
            issuer: address(claimIssuerContract),
            signature: emptyBytes,
            data: abi.encodePacked("Some claim public data."),
            uri: ""
        });
        bytes32 claimForBobSignHash = keccak256(abi.encode(address(bobIdentity), claimForBob.topic, claimForBob.data));
        (uint8 vBob, bytes32 rBob, bytes32 sBob) = vm.sign(claimIssuerSigningKey, claimForBobSignHash);
        claimForBob.signature = abi.encodePacked(rBob, sBob, vBob);

        // bob Identity add Claim
        vm.prank(bobWallet);
        Identity(address(bobIdentity)).addClaim(
            claimForBob.topic,
            claimForBob.scheme,
            claimForBob.issuer,
            claimForBob.signature,
            claimForBob.data,
            claimForBob.uri
        );

        // token mint and config
        vm.startPrank(tokenAgent);
        Token(address(token)).mint(aliceWallet, 1e21);
        Token(address(token)).mint(bobWallet, 5e20);

        agentManager.addAgentAdmin(tokenAdmin);
        vm.stopPrank();

        vm.startPrank(deployer);
        Token(address(token)).addAgent(address(agentManager));
        IdentityRegistry(address(identityRegistryProxy)).addAgent(address(agentManager));
        vm.stopPrank();

        vm.prank(tokenAgent);
        Token(address(token)).unpause();
    }

    // forge test -vvvv --match-test testTREX
    function testTREX() public {}
}
