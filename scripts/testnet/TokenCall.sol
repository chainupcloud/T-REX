// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/token/IToken.sol";

// forge script scripts/testnet/TokenCall.sol:BatchMintCall --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract BatchMintCall is Script {
    IToken token = IToken(0xB745828423625f456A31C4e9b0A7858b1a84F99a);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);
        address[] memory toAddressList = new address[](3);
        toAddressList[0] = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
        toAddressList[1] = 0xe583DC38863aB4b5A94da77A6628e2119eaD4B18;
        toAddressList[2] = 0x3357c09eCf74C281B6f9CCfAf4D894979349AC4B;
        uint256[] memory amountList = new uint256[](3);
        amountList[0] = 10e18;
        amountList[1] = 10e18;
        amountList[2] = 10e18;

        token.batchMint(toAddressList, amountList);

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/TokenCall.sol:PausedCall --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract PausedCall is Script {
    IToken token = IToken(0xB745828423625f456A31C4e9b0A7858b1a84F99a);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        bool paused = token.paused();
        console.log("paused:", paused);

        if (paused) {
            token.unpause();
            bool paused = token.paused();
            console.log("paused:", paused);
        }

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/TokenCall.sol:TransferCall --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract TransferCall is Script {
    IToken token = IToken(0xB745828423625f456A31C4e9b0A7858b1a84F99a);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        token.transfer(0x00dFaaE92ed72A05bC61262aA164f38B5626e106, 1e18);

        vm.stopBroadcast();
    }
}
