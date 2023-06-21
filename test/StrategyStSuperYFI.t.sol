// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console2 as console} from "forge-std/console2.sol";
import {StrategyFixture} from "./utils/StrategyFixture.sol";
import {StrategyParams} from "../src/interfaces/yearn/IVault.sol";

contract StrategyOperationsTest is StrategyFixture {
    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();
    }

    function test_setup_VaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
        assertEq(vault.token(), address(want));
        assertEq(vault.depositLimit(), type(uint256).max);
    }

    // TODO: add additional check on strat params
    function test_setup_StrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(address(strategy.vault()), address(vault));
    }

    /// Test Operations
}
