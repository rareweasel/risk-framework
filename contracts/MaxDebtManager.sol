// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IRiskImpactController.sol";
import "./interfaces/IRiskFramework.sol";
import "./interfaces/yearn/v3/IVaultV3.sol";
import "./interfaces/yearn/v3/IStrategyV3.sol";
import "./interfaces/yearn/v3/IOracle.sol";

contract MaxDebtManager is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    uint256 public constant AVERAGE_PRECISION = 1000;

    IRiskFramework public riskFramework;

    IRiskImpactController public riskImpactController;

    constructor(
        address initialOwnerAddress,
        address initialConfiguratorAddress,
        address initialAdminAddress
    ) {
        require(initialOwnerAddress != address(0), "!initial_owner");
        require(initialConfiguratorAddress != address(0), "!initial_configurator");
        require(initialAdminAddress != address(0), "!initial_admin");

        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(OWNER_ROLE, initialOwnerAddress);
        _setupRole(CONFIGURATOR_ROLE, initialConfiguratorAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, initialAdminAddress);
    }

    function getDebtInfo(address vault, address strategy, address oracle) external view 
    returns (uint256 newMaxDebt, uint256 currentMaxDebt, uint256 currentDebt) {
        address asset = IStrategyV3(strategy).asset();
        uint256 totalAssets = IStrategyV3(strategy).totalAssets();
        uint256 totalAssetsUsd = IOracle(oracle).getNormalizedValueUsdc(asset, totalAssets);
        IVaultV3.StrategyParams memory strategyParams = IVaultV3(vault).strategies(strategy);
        
        (
            ,
            ,
            uint128 averageScore,
        ) = IRiskFramework(riskFramework).getTargetInfo(1, strategy);
        uint256 averagePrecision = IRiskFramework(riskFramework).AVERAGE_PRECISION();
        (IRiskImpactController.Status status, IRiskImpactController.ImpactRange memory impactRange) = IRiskImpactController(riskImpactController).getImpactInfo(totalAssetsUsd, uint8(averageScore / averagePrecision));
        status;

        newMaxDebt = impactRange.max;
        currentDebt = strategyParams.current_debt;
        currentMaxDebt = strategyParams.max_debt;
    }


    /** View Functions */

    /** Internal Functions */

}
