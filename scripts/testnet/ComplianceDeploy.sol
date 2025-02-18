// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/compliance/modular/ModularCompliance.sol";
import "contracts/compliance/modular/modules/TransferRestrictModule.sol";

// forge script scripts/testnet/ComplianceDeploy.sol:TransferRestrictModuleDeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify
// forge script scripts/testnet/ComplianceDeploy.sol:TransferRestrictModuleDeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
// TransferRestrictModule 为地址白名单才可以转账
contract TransferRestrictModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        TransferRestrictModule transferRestrictModule = new TransferRestrictModule();
        console.log("transferRestrictModule:", address(transferRestrictModule));
        transferRestrictModule.initialize();
        console.log("transferRestrictModule initialize success.");

        vm.stopBroadcast();
    }
}
