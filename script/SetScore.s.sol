// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../contracts/interfaces/IRiskFramework.sol";

/**
 forge script ./script/SetScore.s.sol:SetScoreScript --rpc-url <rpc-url> --etherscan-api-key <etherscan-api-key> --broadcast --verify -vvvv
*/
contract SetScoreScript is Script {
    function run() external {
        IRiskFramework riskFramework = IRiskFramework(vm.envAddress("RISK_FRAMEWORK"));
        uint256 deployerPrivateKey = vm.envUint("PK_ACCOUNT");
        uint256 network = vm.envUint("NETWORK");
        address[] memory targets = vm.envAddress("TARGETS_LIST", ",");
        
        uint256 score = vm.envUint("SCORE");
        uint128 score128 = uint128(score);

        vm.startBroadcast(deployerPrivateKey);
        riskFramework.setScore(network, targets, score128);
        vm.stopBroadcast();
    }
}