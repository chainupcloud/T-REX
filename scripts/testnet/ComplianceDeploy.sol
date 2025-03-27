// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/compliance/modular/ModularCompliance.sol";
import "contracts/compliance/modular/modules/TransferRestrictModule.sol";
import "contracts/compliance/modular/modules/CountryAllowModule.sol";
import "contracts/compliance/modular/modules/CountryRestrictModule.sol";
import "contracts/compliance/modular/modules/MaxBalanceModule.sol";

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

// forge script scripts/testnet/ComplianceDeploy.sol:CountryAllowModuleDeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
// CountryAllowModule 国家白名单
contract CountryAllowModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        CountryAllowModule module = new CountryAllowModule();
        console.log("CountryAllowModule:", address(module));
        module.initialize();
        console.log("CountryAllowModule initialize success.");

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/ComplianceDeploy.sol:CountryRestrictModuleDeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
// CountryRestrictModule 国家黑名单
contract CountryRestrictModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        CountryRestrictModule module = new CountryRestrictModule();
        console.log("CountryRestrictModule:", address(module));
        module.initialize();
        console.log("CountryRestrictModule initialize success.");

        vm.stopBroadcast();
    }
}

// forge script scripts/testnet/ComplianceDeploy.sol:MaxBalanceModuleDeployScript --rpc-url $RPC_URL --slow --broadcast --retries 10 --delay 30 --verify --verifier=blockscout --verifier-url=https://eth-holesky.blockscout.com/api/
// MaxBalanceModule 地址最大持有量限制
contract MaxBalanceModuleDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        MaxBalanceModule module = new MaxBalanceModule();
        console.log("MaxBalanceModule:", address(module));
        module.initialize();
        console.log("MaxBalanceModule initialize success.");

        vm.stopBroadcast();
    }
}
