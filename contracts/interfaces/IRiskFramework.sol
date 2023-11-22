// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRiskFramework {

    function setScoreAndTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList, uint128[] calldata _scores) external;
    function setScoreAndTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList, uint128 _score) external;
    function setTargetsStatus(uint256 _network, address[] calldata _targets, bool isActive) external;
    function setScore(uint256 _network, address[] calldata _targets, uint128 _score) external;
    function setTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList) external;
    function removeTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList) external;
    function copyScores(
        uint256 _network,
        address _fromTarget,
        address[] calldata _toTargets,
        bytes32[] calldata _tagsList
    ) external;

    /** View Functions */

    function AVERAGE_PRECISION() external view returns (uint256);

    function ACTIVE() external view returns (bool);

    function INACTIVE() external view returns (bool);

    function currentScores() external view returns (uint256);

    function getTargetInfo(uint256 _network, address _target) external view returns (uint128 scores, uint8[] memory scoresList, uint128 averageScore, bytes32[] memory tagsList, bool isActive);

    function fromScoreToList(uint128 _score) external view returns (uint8[] memory scoresList, uint128 averageScore);

    function fromListToScore(uint8[] calldata _scoresList) external view returns (uint128 score, uint128 averageScore);

    function getTargetsByTag(bytes32 _tag) external view returns (address[] memory targets);

    function getNetworksByTarget(address _target) external view returns (uint256[] memory networks);

    function getScoresByTarget(uint256 _network, address _target) external view returns (uint128);

    function isTargetActive(uint256 _network, address _target) external view returns (bool);

    /** Events */

    event ScoreSet(uint256 indexed _network, address indexed target, uint128 score);
    event TagSet(uint256 indexed _network, address indexed target, bytes32 indexed tag);
    event TagRemoved(uint256 indexed _network, address indexed target, bytes32 indexed tag);
    event ScoreCopied(uint256 indexed network, address indexed fromTarget, address indexed toTarget, uint128 score);
    event TargetStatusSet(uint256 indexed network, address indexed target, bool indexed isActive);
}

