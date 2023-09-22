// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libs/ScoresLib.sol";
import "./interfaces/yearn/v3/IOracle.sol";
import "./interfaces/IRiskFramework.sol";

contract RiskFramework is IRiskFramework, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using ScoresLib for *;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    uint256 public constant override AVERAGE_PRECISION = 1000;

    /**
         #15   #14   #13   #12   #11   #10    #9    #8    #7    #6    #5    #4    #3    #2   #1
        00000 00000 00000 00000 00000 00000 00000 00000 01010 01010 01010 01010 01010 01010 01010

        Max Scores (bits) = 15 scores * 5 bits = 75 bits
     */
    uint256 public constant MAX_SCORES_BITS = 75;
    /**
        Max scores per group is 15 (or MAX_SCORES_BITS).
     */
    uint256 public constant MAX_SCORES = 15;

    uint256 public constant BITS_PER_SCORES = 5;

    // Tag name (lowercase) => list of targets
    mapping(bytes32 => EnumerableSet.AddressSet) internal targetsByTag;

    // Target => List of network ids
    mapping(address => EnumerableSet.UintSet) internal networksByTarget;

    // Network id => Target => List of tags
    mapping(uint256 => mapping(address => EnumerableSet.Bytes32Set)) internal tagsByTarget;

    // Network id => Target => scores
    mapping(uint256 => mapping(address => uint128)) internal scoresByTarget;

    /**
        Current available scores
     */
    uint256 public override currentScores;

    constructor(
        address _initialOwnerAddress,
        address _initialConfiguratorAddress,
        address _initialAdminAddress,
        uint256 _initialCurrentScores
    ) {
        require(_initialOwnerAddress != address(0), "!initial_owner");
        require(_initialConfiguratorAddress != address(0), "!initial_configurator");
        require(_initialAdminAddress != address(0), "!initial_admin");
        require(_initialCurrentScores > 0 && _initialCurrentScores <= MAX_SCORES, "!initial_scores");

        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(OWNER_ROLE, _initialOwnerAddress);
        _setupRole(CONFIGURATOR_ROLE, _initialConfiguratorAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _initialAdminAddress);
        currentScores = _initialCurrentScores;
    }

    function setScoreAndTags(
        uint256 _network,
        address[] calldata _targets,
        bytes32[] calldata _tagsList,
        uint128[] calldata _scores
    ) external override {
        require(_targets.length > 0, "!targets");
        require(_scores.length > 0, "!scores");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 i = 0; i < totalTargets; ++i) {
            address target = _targets[i];
            for (uint256 j = 0; j < totalTargets; ++j) {
                uint128 _score = _scores[j];
                _setScore(_network, target, _score);
                _setTags(_network, target, _tagsList);
            }
        }
    }

    function setScoreAndTags(
        uint256 _network,
        address[] calldata _targets,
        bytes32[] calldata _tagsList,
        uint128 _score
    ) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _setScore(_network, target, _score);
            _setTags(_network, target, _tagsList);
        }
    }

    function setScore(uint256 _network, address[] calldata _targets, uint128 _score) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _setScore(_network, target, _score);
        }
    }

    function setTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _setTags(_network, target, _tagsList);
        }
    }

    function removeTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _removeTags(_network, target, _tagsList);
        }
    }

    /** View Functions */

    function getTargetInfo(
        uint256 _network,
        address _target
    )
        external
        view
        override
        returns (uint128 scores, uint8[] memory scoresList, uint128 averageScore, bytes32[] memory tagsList)
    {
        scores = scoresByTarget[_network][_target];
        tagsList = tagsByTarget[_network][_target].values();
        (scoresList, averageScore) = fromScoreToList(scores);
    }

    function fromScoreToList(
        uint128 _score
    ) public view override returns (uint8[] memory scoresList, uint128 averageScore) {
        // 5506139203, 35, 15, 5
        // Scores, total bits, start bit (rigth to left), bits per score
        // scores.getNBits(uint256 x, uint256 start, uint256 offset)
        scoresList = new uint8[](currentScores);
        uint128 totalScores;

        for (uint256 index = 0; index < currentScores; ++index) {
            uint256 startBit = (index + 1) * 5;
            uint256 aScore = _score.getNBits(MAX_SCORES_BITS, startBit, BITS_PER_SCORES);
            totalScores += uint8(aScore);
            scoresList[currentScores - index - 1] = uint8(aScore);
        }
        averageScore = uint128((totalScores * AVERAGE_PRECISION) / currentScores);
    }

    function fromListToScore(
        uint8[] calldata _scoresList
    ) public view override returns (uint128 score, uint128 averageScore) {
        if (_scoresList.length != currentScores) {
            return (0, 0);
        }
        uint256 _currentScores = _scoresList.length;

        uint128 totalScores;
        for (uint256 index = 0; index < _currentScores; ++index) {
            if (index == 0) {
                score = uint128(_scoresList[index]);
            } else {
                score = uint128(score.shiftLeft(BITS_PER_SCORES)) | uint128(_scoresList[index]);
            }
            totalScores += uint8(_scoresList[index]);
        }
        averageScore = uint128((totalScores * AVERAGE_PRECISION) / currentScores);
    }

    function getTargetsByTag(bytes32 _tag) external view override returns (address[] memory targets) {
        targets = targetsByTag[_tag].values();
    }

    function getNetworksByTarget(address _target) external view override returns (uint256[] memory networks) {
        networks = networksByTarget[_target].values();
    }

    function getScoresByTarget(uint256 _network, address _target) external view override returns (uint128) {
        return scoresByTarget[_network][_target];
    }

    /** Internal Functions */

    function _setScore(uint256 _network, address target, uint128 score) internal {
        require(target != address(0x0), "!target");
        require(score > 0, "!score");

        scoresByTarget[_network][target] = score;
        _addNetworkInTargetIfNeeded(_network, target);

        emit ScoreSet(_network, target, score);
    }

    function _setTags(uint256 _network, address target, bytes32[] calldata tagsList) internal {
        require(target != address(0x0), "!target");
        require(tagsList.length > 0, "!tags_list");

        for (uint256 index = 0; index < tagsList.length; ++index) {
            bytes32 tag = tagsList[index];
            require(tag != "", "!tag_empty");
            require(tagsByTarget[_network][target].contains(tag) == false, "!tag_already_set");
            require(targetsByTag[tag].contains(target) == false, "!target_already_set");
            targetsByTag[tag].add(target);
            tagsByTarget[_network][target].add(tag);
            _addNetworkInTargetIfNeeded(_network, target);
        }

        emit TagsSet(_network, target, tagsList);
    }

    function _addNetworkInTargetIfNeeded(uint256 _network, address _target) internal {
        if (networksByTarget[_target].contains(_network) == false) {
            networksByTarget[_target].add(_network);
        }
    }

    function _removeTags(uint256 _network, address target, bytes32[] calldata tagsList) internal {
        require(target != address(0x0), "!target");
        require(tagsList.length > 0, "!tags_list");

        for (uint256 index = 0; index < tagsList.length; ++index) {
            bytes32 tag = tagsList[index];
            require(tag != "", "!tag_empty");

            require(tagsByTarget[_network][target].remove(tag) == true, "!tag_removed");
            require(targetsByTag[tag].remove(target) == true, "!target_removed");
        }

        emit TagsRemoved(_network, target, tagsList);
    }
}
