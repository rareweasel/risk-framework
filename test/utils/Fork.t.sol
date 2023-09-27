// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {ImpactCalculator} from "../../contracts/lens/ImpactCalculator.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract ForkTest is Test {

    string public constant MAINNET_RPC_URL = "MAINNET_RPC_URL";
    string public constant POLYGON_RPC_URL = "POLYGON_RPC_URL";
    string public constant BASE_RPC_URL = "BASE_RPC_URL";
    string public constant FANTOM_RPC_URL = "FANTOM_RPC_URL";
    string public constant ARBITRUM_ONE_RPC_URL = "ARBITRUM_ONE_RPC_URL";
    string public constant AVAX_ONE_RPC_URL = "AVAX_ONE_RPC_URL";
    
    ImpactCalculator internal impactCalculator;
    uint256 internal forkId;

    function _setUp() internal {
        impactCalculator = new ImpactCalculator();
    }

    function _activateFork(string memory urlOrAlias) internal returns (uint256) {
        forkId = vm.createSelectFork(vm.rpcUrl(urlOrAlias));
        assertEq(vm.activeFork(), forkId, "invalid fork id");
        return forkId;
    }
}
