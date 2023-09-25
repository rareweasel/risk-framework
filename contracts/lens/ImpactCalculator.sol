// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../interfaces/yearn/v3/IVaultV3.sol";
import "../interfaces/yearn/v2/IStrategyV2.sol";

contract ImpactCalculator {

    function getImpacts(address[] calldata items) external view returns (
        uint256[] memory impacts,
        address[] memory assets,
        uint8[] memory decimals
    ) {
        uint256 totalItems = items.length;
        impacts = new uint256[](totalItems);
        assets = new address[](totalItems);
        decimals = new uint8[](totalItems);
        for (uint256 i = 0; i < totalItems; i++) {
            (uint256 impact, address asset, uint8 decimal) = _getImpact(items[i]);
            impacts[i] = impact;
            assets[i] = asset;
            decimals[i] = decimal;
        }
    }


    /** View Functions */

    /** Internal Functions */
    function _getContractSize(address item) internal view returns (uint256) {
        uint256 csize;
        assembly {
            csize := extcodesize(item)
        }
        return csize;
    }

    function _getImpact(address item) internal view returns (uint256 impact, address asset, uint8 decimals) {
        // https://ethereum.stackexchange.com/questions/129150/solidity-try-catch-call-to-external-non-existent-address-method
        if (_getContractSize(item) == 0) {
            return (0, address(0x0), 0);
        }
        // V3
        try IVaultV3(item).totalAssets() returns (uint256 result) {
            address _asset = IVaultV3(item).asset();
            return (result, _asset, IVaultV3(_asset).decimals());
        } catch {}

        // yETH

        // yCRV

        // V2
        try IStrategyV2(item).estimatedTotalAssets() returns (uint256 result) {
            address _asset = IStrategyV2(item).want();
            return (result, _asset, IStrategyV2(_asset).decimals());
        } catch {}
    }

}
