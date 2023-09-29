// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../contracts/lens/ImpactCalculator.sol";

contract ImpactCalculatorScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK_ACCOUNT");
        bytes32 versionSalt = vm.envBytes32("SALT");
        vm.startBroadcast(deployerPrivateKey);
        
        ImpactCalculator a = new ImpactCalculator{salt: versionSalt}();
        address[] memory items = new address[](1);
        items[0] = address(0x0);
        a.getImpacts(items);
        vm.stopBroadcast();
    }
}