// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IRiskImpactController {
    
    enum Status {
        Undefined,
        Green,
        Yellow,
        Red
    }

    struct ImpactRange {
        uint256 max;
        uint16 impact;
    }

    function setStatusesBy(uint16 impact, Status[] calldata statusesList) external;

    function setImpacts(ImpactRange[] calldata impactsList) external;

    /** View Functions */

    function maxStatusPerImpact() external view returns (uint16);

    function getImpactInfo(uint256 tvl, uint8 score) external view returns (Status status, ImpactRange memory impactRange);

    function getImpactRange(uint256 value) external view returns (ImpactRange memory impact);

    function getImpactRangeAt(uint256 index) external view returns (ImpactRange memory impact);

}

