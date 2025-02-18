// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/compliance/modular/ModularCompliance.sol";
import "contracts/compliance/modular/IModularCompliance.sol";
import "contracts/compliance/modular/modules/TransferRestrictModule.sol";

// forge script scripts/testnet/ComplianceCall.sol:IModularComplianceCall --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30
contract IModularComplianceCall is Script {
    address moduleAddress = 0xd9b7d77Be3b2d58f8d2cD39099a7779Fb6C5f4BC;
    IModularCompliance modularCompliance = IModularCompliance(0xBE61f14C5638aeCD3f05C280b015337A138dF485);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory allowUsers = new address[](3);
        allowUsers[0] = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;
        allowUsers[1] = 0xe583DC38863aB4b5A94da77A6628e2119eaD4B18;
        allowUsers[2] = 0x3357c09eCf74C281B6f9CCfAf4D894979349AC4B;

        bytes memory callData = abi.encodeWithSignature("batchAllowUsers(address[])", allowUsers);
        modularCompliance.callModuleFunction(callData, moduleAddress);

        vm.stopBroadcast();
    }
}
