// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces//IRiskImpactController.sol";

contract RiskImpactController is IRiskImpactController, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    uint256 public constant AVERAGE_PRECISION = 1000;

    ImpactRange[] internal impacts;

    // Impact => Status: Green (1), Yellow (2), Red (3)
    mapping(uint16 => Status[]) internal statusByImpact;

    uint16 public override maxStatusPerImpact;

    /*
    Impact / Odds       (1) Rare | (2) Unlikely | (3) Even Chance | (4) Likely | (5) Almost certain
    (5) Critical
    (4) High
    (3) Severe
    (2) Medium
    (1) Low

    avg score: 3 and tvl: 20 MM =>
        - Get impact for tvl 20 MM (array of impacts)
        - Get a


    (5) Critical    1500 MM
    (4) High        500 MM
    (3) Severe      200 MM
    (2) Medium      80 MM
    (1) Low         10 MM

    5 MM    => 1
    15 MM   => 2
    50 MM   => 2
    120 MM  => 3
    2500 MM => 5
    */


    constructor(
        address initialOwnerAddress,
        address initialConfiguratorAddress,
        address initialAdminAddress,
        uint16 initialMaxStatusPerImpact
    ) {
        require(initialOwnerAddress != address(0), "!initial_owner");
        require(initialConfiguratorAddress != address(0), "!initial_configurator");
        require(initialAdminAddress != address(0), "!initial_admin");
        require(initialMaxStatusPerImpact > 0, "!max_status_per_impact");

        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(OWNER_ROLE, initialOwnerAddress);
        _setupRole(CONFIGURATOR_ROLE, initialConfiguratorAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, initialAdminAddress);
        maxStatusPerImpact = initialMaxStatusPerImpact;
    }

    function setStatusesBy(uint16 impact, Status[] calldata statusesList) external override {
        require(hasRole(CONFIGURATOR_ROLE, msg.sender), "!configurator");
        require(impact > 0, "!impact");
        require(statusesList.length <= maxStatusPerImpact, "!max_statuses");

        for (uint256 index = 0; index < statusesList.length; ++index) {
            statusByImpact[impact][index] = statusesList[index];
        }
    }

    function setImpacts(ImpactRange[] calldata impactsList) external override {
        require(hasRole(CONFIGURATOR_ROLE, msg.sender), "!configurator");
        require(impactsList.length > 0, "!impacts");

        for (uint256 index = 0; index < impactsList.length; ++index) {
            impacts[index] = impactsList[index];
        }
    }

    /** View Functions */

    function getImpactInfo(uint256 tvl, uint8 score) external override
        view returns (Status status, ImpactRange memory impactRange) {
        impactRange = this.getImpactRange(tvl);
        Status[] memory statuses = statusByImpact[impactRange.impact];
        status = statuses[score];
    }

    function getImpactRange(uint256 value) external override view returns (ImpactRange memory impact) {
        if (impacts.length == 0) {
            return ImpactRange(0, 0);
        }
        for (uint256 i = 0; i < impacts.length; ++i) {
            if (value <= impacts[i].max) {
                impact = impacts[i];
                break;
            }
        }
        impact = impacts[impacts.length - 1];
    }

    function getImpactRangeAt(uint256 index) external override view returns (ImpactRange memory impact) {
        require(index < impacts.length, "!index");
        impact = impacts[index];
    }

    /** Internal Functions */

}

