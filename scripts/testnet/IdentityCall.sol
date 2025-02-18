// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@onchain-id/solidity/contracts/Identity.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "@onchain-id/solidity/contracts/factory/IIdFactory.sol";

import "contracts/token/IToken.sol";
import "contracts/registry/implementation/IdentityRegistry.sol";
import "contracts/registry/interface/IIdentityRegistry.sol";

// forge script scripts/testnet/IdentityCall.sol:BatchCreateIdentity --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract BatchCreateIdentity is Script {
    IIdentityRegistry identityRegistry = IIdentityRegistry(0xd190230aADCbF629c9ce642d8270cEFd33d6DEd9);
    IIdFactory idFactory = IIdFactory(0xB1C458e6804CB8b1D1cF509466ff506222295422);

    address dev = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
    address dev1 = 0xe583DC38863aB4b5A94da77A6628e2119eaD4B18;
    address dev2 = 0x3357c09eCf74C281B6f9CCfAf4D894979349AC4B;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        address devId = idFactory.createIdentity(dev, "dev");
        address dev1Id = idFactory.createIdentity(dev1, "dev1");
        address dev2Id = idFactory.createIdentity(dev2, "dev2");
        console.log("devId:", devId);
        console.log("dev1Id:", dev1Id);
        console.log("dev2Id:", dev2Id);

        address[] memory _userAddresses = new address[](3);
        _userAddresses[0] = dev;
        _userAddresses[1] = dev1;
        _userAddresses[2] = dev2;
        IIdentity[] memory _identities = new IIdentity[](3);
        _identities[0] = IIdentity(devId);
        _identities[1] = IIdentity(dev1Id);
        _identities[2] = IIdentity(dev2Id);
        uint16[] memory _countries = new uint16[](3);
        _countries[0] = 156;
        _countries[1] = 156;
        _countries[2] = 156;

        identityRegistry.batchRegisterIdentity(_userAddresses, _identities, _countries);

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/IdentityCall.sol:CreateIdentity --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract CreateIdentity is Script {
    IIdentityRegistry identityRegistry = IIdentityRegistry(0xd190230aADCbF629c9ce642d8270cEFd33d6DEd9);
    IIdFactory idFactory = IIdFactory(0xB1C458e6804CB8b1D1cF509466ff506222295422);

    address wallet = 0x00dFaaE92ed72A05bC61262aA164f38B5626e106;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        address mainId = idFactory.createIdentity(wallet, "main");
        console.log("mainId:", mainId);

        address[] memory _userAddresses = new address[](1);
        _userAddresses[0] = wallet;
        IIdentity[] memory _identities = new IIdentity[](1);
        _identities[0] = IIdentity(mainId);
        uint16[] memory _countries = new uint16[](1);
        _countries[0] = 156;

        identityRegistry.batchRegisterIdentity(_userAddresses, _identities, _countries);

        vm.stopBroadcast();
    }
}
