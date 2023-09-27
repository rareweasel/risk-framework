// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from "../test/utils/Fork.t.sol";
import "forge-std/console.sol";
import "./mock/VaultV3Mock.sol";

contract ImpactCalculatorTest is ForkTest {

    function _setUp(string memory urlOrAlias) internal {
        super._activateFork(urlOrAlias);
        super._setUp();
    }

    function test_getImpacts_succesfull_v3_vault() external {
        _setUp(POLYGON_RPC_URL);
        address[] memory items = new address[](1);
        items[0] = address(0xcAA17796bB3d4a71005CeBd817CFEebF85D581b7);

        (uint256[] memory impacts, address[] memory assets, uint8[] memory decimals) = impactCalculator.getImpacts(items);


        assertEq(impacts.length, 1, "invalid impacts length");
        assertEq(assets.length, 1, "invalid assets length");
        assertEq(decimals.length, 1, "invalid decimals length");
        assertTrue(impacts[0] > 0, "invalid impact");
        assertNotEq(assets[0], address(0x0), "invalid asset");
        assertEq(decimals[0], 6, "invalid decimals");
    }

    function test_getImpacts_succesfull_v2_vault() external {
        _setUp(MAINNET_RPC_URL);
        address[] memory items = new address[](1);
        items[0] = address(0x01d127D90513CCB6071F83eFE15611C4d9890668);

        (uint256[] memory impacts, address[] memory assets, uint8[] memory decimals) = impactCalculator.getImpacts(items);

        assertEq(impacts.length, 1, "invalid impacts length");
        assertEq(assets.length, 1, "invalid assets length");
        assertEq(decimals.length, 1, "invalid decimals length");
        assertTrue(impacts[0] > 0, "invalid impact");
        assertNotEq(assets[0], address(0x0), "invalid asset");
        assertEq(decimals[0], 18, "invalid decimals");
    }

    function test_getImpacts_succesfull_partially() external {
        _setUp(MAINNET_RPC_URL);
        address[] memory items = new address[](2);
        items[0] = address(0x01d127D90513CCB6071F83eFE15611C4d9890668);
        items[1] = address(0xcAA17796bB3d4a71005CeBd817CFEebF85D581b7);

        (uint256[] memory impacts, address[] memory assets, uint8[] memory decimals) = impactCalculator.getImpacts(items);

        assertEq(impacts.length, 2, "invalid impacts length");
        assertEq(assets.length, 2, "invalid assets length");
        assertEq(decimals.length, 2, "invalid decimals length");
        assertTrue(impacts[0] > 0, "invalid impact");
        assertNotEq(assets[0], address(0x0), "invalid asset");
        assertEq(decimals[0], 18, "invalid decimals");
        assertEq(impacts[1], 0, "invalid impact");
        assertEq(assets[1], address(0x0), "invalid asset");
        assertEq(decimals[1], 0, "invalid decimals");
    }

    function test_getImpacts_invalid_address_no_contract() external {
        _setUp(POLYGON_RPC_URL);
        address[] memory items = new address[](1);
        items[0] = address(0xcaa17796BB3D4A71005cEbd817CFEebF85d50000);

        (uint256[] memory impacts, address[] memory assets, uint8[] memory decimals) = impactCalculator.getImpacts(items);

        assertEq(impacts.length, 1, "invalid impacts length");
        assertEq(assets.length, 1, "invalid assets length");
        assertEq(decimals.length, 1, "invalid decimals length");
        assertEq(impacts[0], 0, "invalid impact");
        assertEq(assets[0], address(0x0), "invalid asset");
        assertEq(decimals[0], 0, "invalid decimals");
    }

    function test_getImpacts_invalid_function_signature() external {
        _setUp(POLYGON_RPC_URL);
        address[] memory items = new address[](1);
        items[0] = address(new VaultV3Mock());
        // It fails due to https://ethereum.stackexchange.com/questions/129150/solidity-try-catch-call-to-external-non-existent-address-method
        vm.expectRevert();
        impactCalculator.getImpacts(items);
    }
}
