// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../interfaces/yearn/v3/IVaultV3.sol";
import "../interfaces/yearn/v2/IStrategyV2.sol";

/**
 * @title ImpactCalculator contract
 * @author Security Team @ Yearn Finance
 * @notice this contract is used to get the impact of vaults/strategies on the Yearn Finance protocol.
 * @notice it supports v2 and v3 strategies and vaults.
 * @dev it uses try/catch to avoid reverting on non-existent methods in the different versions.
 * @dev since it is stateless, eventually it might be updated with new features.
 */
contract ImpactCalculator {

    /**
     * Gets the impact of a list of vaults/strategies on the Yearn Finance protocol.
     * 
     * @dev if an empty list is passed, it will return 0 items for each array.
     * @param items list of vaults/strategies to get the impact from.
     * @return impacts the list of impact for each item in the list (same position).
     * @return assets the list of assets (tokens) for each item in the list (same position).
     * @return decimals the list of decimals for each token in the returned list (same position).
     */
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

    /**
     * Gets the contract size for a given address.
     * 
     * @param item the address to get the contract size from.
     */
    function _getContractSize(address item) internal view returns (uint256) {
        uint256 csize;
        assembly {
            csize := extcodesize(item)
        }
        return csize;
    }

    /**
     * Gets the impact of a vault/strategy on the Yearn Finance protocol.
     * 
     * @dev if the item is not a contract, it returns empty values due to this issue https://ethereum.stackexchange.com/questions/129150/solidity-try-catch-call-to-external-non-existent-address-method
     * @param item the address of the vault/strategy to get the impact from.
     * @return impact the impact of the vault/strategy on the Yearn Finance protocol.
     * @return asset the underlying asset (token) of the vault/strategy.
     * @return decimals the decimals of the underlying asset (token).
     */
    function _getImpact(address item) internal view returns (uint256 impact, address asset, uint8 decimals) {
        if (_getContractSize(item) == 0) {
            return (0, address(0x0), 0);
        }
        // V3
        try IVaultV3(item).totalAssets() returns (uint256 result) {
            address _asset = IVaultV3(item).asset();
            return (result, _asset, IVaultV3(_asset).decimals());
        } catch {}

        // V2
        try IStrategyV2(item).estimatedTotalAssets() returns (uint256 result) {
            address _asset = IStrategyV2(item).want();
            return (result, _asset, IStrategyV2(_asset).decimals());
        } catch {}
    }

}
