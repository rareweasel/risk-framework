// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRiskFramework {

    function setScores(address target, bytes32[] calldata tagsList, uint128 scores) external;

    /** View Functions */

    function AVERAGE_PRECISION() external view returns (uint256);

    function scoresByTarget(address target) external view returns (uint128);

    function currentScores() external view returns (uint256);

    function getTargetInfo(address target) external view returns (uint128 scores, uint8[] memory scoresList, uint128 averageScore, bytes32[] memory tagsList);

    function getScores(uint128 scores) external view returns (uint8[] memory scoresList, uint128 averageScore);

    /** Events */

    event TargetScored(address indexed target, bytes32[] indexed tagsList, uint128 scores);
}

