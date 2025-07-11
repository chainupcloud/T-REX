// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/token/MintableERC721.sol";

// forge script scripts/testnet/MintableERC721.s.sol:MintableERC721Script --rpc-url $RPC_URL --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
contract MintableERC721Script is Script {

    MintableERC721 public token;

    address admin = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
    address mintBurner = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        token = new MintableERC721("TestNFT", "TF002", "https://meta.chainnova.io/",admin, mintBurner);
        console.log("nft token:", address(token));

        vm.stopBroadcast();
    }

}

// forge script scripts/testnet/MintableERC721.s.sol:MintScript --rpc-url $RPC_URL --broadcast --retries 10 --delay 30
contract MintScript is Script {

    // nft token: 0x1BF0b4311819E9aAb6B8EC38c4dAAe499d8712A8
    // nft token: 0xdc1859101AB0D5Dc3D9453408F4CacfA77698e96
    MintableERC721 public token = MintableERC721(0xdc1859101AB0D5Dc3D9453408F4CacfA77698e96);

    // my mpc address: 0xaDd48dbAd2c0AB0b5CC3d8ad0660DF4E8Dad313B
    // system mpc address: 0x4E2b8894cC6d82fB224fdEfc6d249D2A30755141
    address user = 0x4E2b8894cC6d82fB224fdEfc6d249D2A30755141;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        token.mint(user,3);

        vm.stopBroadcast();
    }

}
