// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/compliance/modular/ModularCompliance.sol";
import "contracts/compliance/modular/modules/TransferRestrictModule.sol";
import "contracts/compliance/modular/modules/CountryAllowModule.sol";
import "contracts/compliance/modular/modules/CountryRestrictModule.sol";
import "contracts/compliance/modular/modules/MaxBalanceModule.sol";

// forge script scripts/mainnet/ComplianceDeploy.s.sol:CountryAllowModuleDeployScript --rpc-url $RPC_URL --broadcast --retries 10 --delay 30 --verify --etherscan-api-key=$ETHERSCAN_API_KEY
// CountryAllowModule
contract CountryAllowModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CountryAllowModule module = new CountryAllowModule();
        console.log("CountryAllowModule:", address(module));
        module.initialize();
        console.log("CountryAllowModule initialize success.");

        vm.stopBroadcast();
    }
}

// forge script scripts/mainnet/ComplianceDeploy.s.sol:CountryRestrictModuleDeployScript --rpc-url $RPC_URL --broadcast --retries 10 --delay 30 --verify --etherscan-api-key=$ETHERSCAN_API_KEY
// CountryRestrictModule
contract CountryRestrictModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CountryRestrictModule module = new CountryRestrictModule();
        console.log("CountryRestrictModule:", address(module));
        module.initialize();
        console.log("CountryRestrictModule initialize success.");

        vm.stopBroadcast();
    }
}
