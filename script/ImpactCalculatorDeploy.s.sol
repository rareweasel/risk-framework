// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../contracts/lens/ImpactCalculator.sol";

contract ImpactCalculatorDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK_ACCOUNT");
        bytes32 versionSalt = vm.envBytes32("SALT");
        vm.startBroadcast(deployerPrivateKey);
        
        new ImpactCalculator{salt: versionSalt}();
        vm.stopBroadcast();
    }
}