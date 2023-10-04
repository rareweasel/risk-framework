// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libs/ScoresLib.sol";
import "./interfaces/yearn/v3/IOracle.sol";
import "./interfaces/IRiskFramework.sol";

/**
 * @title RiskFramework contract
 * @author Security Team @ Yearn Finance
 * @notice This contract is used to store the risk scores and tags of all the multiple vaults and strategies from v2 and v3.
 * @notice The tags are agnostic to the network, so the same tag can be used in multiple networks. It means a query will get as result all the targets with that tag in all the networks.
 * @dev It uses bitwise operators to pack the scores in just one variable (uint128). More info at ScoresLib.sol
 */
contract RiskFramework is IRiskFramework, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using ScoresLib for *;

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
    /**
        Bits per score is 5 (or MAX_SCORES_BITS / MAX_SCORES).
     */
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

    /**
     * Creates a new RiskFramework contract.
     * 
     * @param _initialConfiguratorAddress address that will be able to set the scores.
     * @param _initialAdminAddress address that will manage the roles.
     * @param _initialCurrentScores roles available to set.
     */
    constructor(
        address _initialConfiguratorAddress,
        address _initialAdminAddress,
        uint256 _initialCurrentScores
    ) {
        require(_initialConfiguratorAddress != address(0), "!initial_configurator");
        require(_initialAdminAddress != address(0), "!initial_admin");
        require(_initialCurrentScores > 0 && _initialCurrentScores <= MAX_SCORES, "!initial_scores");

        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _grantRole(CONFIGURATOR_ROLE, _initialConfiguratorAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdminAddress);
        currentScores = _initialCurrentScores;
    }

    /**
     * Sets a list of scores to a list of targets. Each score will be set to the target in the same position from the target list.
     * 
     * @notice this function should be used to set different scores to different targets.
     * @dev see #setScoreAndTags(uint256, address[], bytes32[], uint128) to set the same score to all the targets.
     * @dev the length from the targets list and the scores list must be the same.
     * @dev the sender must have the configurator role.
     * @param _network network id where the targets and scores will be located.
     * @param _targets list of targets to set the scores.
     * @param _tagsList list of tags to set for all the targets.
     * @param _scores list of scores to set to the targets.
     */
    function setScoreAndTags(
        uint256 _network,
        address[] calldata _targets,
        bytes32[] calldata _tagsList,
        uint128[] calldata _scores
    ) external override {
        require(_targets.length > 0, "!targets");
        require(_scores.length > 0, "!scores");
        require(_targets.length == _scores.length, "!target_scores_length");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 i = 0; i < totalTargets; ++i) {
            address target = _targets[i];
            uint128 _score = _scores[i];
            _setScore(_network, target, _score);
            _setTags(_network, target, _tagsList);
        }
    }

    /**
     * Sets the same score to multiple targets.
     * 
     * @notice this function should be used to set the same score to different targets.
     * @dev see #setScoreAndTags(uint256, address[], bytes32[], uint128[]) to set multiple scores to multiple targets.
     * @dev the sender must have the configurator role.
     * @param _network network id where the targets and score will be located.
     * @param _targets list of targets to set the score.
     * @param _tagsList list of tags to set for all the targets.
     * @param _score score to set to the targets.
     */
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

    /**
     * Sets only a score to a list of targets.
     * 
     * @dev the sender must have the configurator role.
     * @param _network network id where the targets and score will be located.
     * @param _targets list of targets to set the score.
     * @param _score score to set to the targets.
     */
    function setScore(uint256 _network, address[] calldata _targets, uint128 _score) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _setScore(_network, target, _score);
        }
    }

    /**
     * Sets only a list of tags to all the targets.
     * 
     * @dev the sender must have the configurator role.
     * @param _network network id where the targets and score will be located.
     * @param _targets list of targets to set the score.
     * @param _tagsList list of tags to set for all the targets.
     */
    function setTags(uint256 _network, address[] calldata _targets, bytes32[] calldata _tagsList) external override {
        require(_targets.length > 0, "!targets");
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!configurator");

        uint256 totalTargets = _targets.length;
        for (uint256 index = 0; index < totalTargets; ++index) {
            address target = _targets[index];
            _setTags(_network, target, _tagsList);
        }
    }

    /**
     * Removes a list of tags from from all the targets from the list.
     * 
     * @dev the sender must have the configurator role.
     * @param _network network id where the targets and score will be located.
     * @param _targets list of targets to remove the tags.
     * @param _tagsList list of tags to remove from all the targets.
     */
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

    /**
     * Gets all information for a given target and network.
     * 
     * @param _network network id where the target is located.
     * @param _target target address to get the information.
     * @return scores risk score in uint128 (packed) format.
     * @return scoresList risk scores unpacked in uint8 format.
     * @return averageScore the average score of all the scores. To avoid precision loss, the score is multiplied by AVERAGE_PRECISION.
     * @return tagsList list of tags for the target.
     */
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

    /**
     * Converts a score in uint128 (packed) format to a list of uint8 scores.
     * 
     * @param _score packed score.
     * @return scoresList list of uint8 scores.
     * @return averageScore the average score of all the scores. To avoid precision loss, the score is multiplied by AVERAGE_PRECISION.
     */
    function fromScoreToList(
        uint128 _score
    ) public view override returns (uint8[] memory scoresList, uint128 averageScore) {
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

    /**
     * Converts a list of uint8 scores (unpacked) to a score in uint128 (packed) format.
     * 
     * @param _scoresList list of uint8 scores.
     * @return score packed score.
     * @return averageScore the average score of all the scores. To avoid precision loss, the score is multiplied by AVERAGE_PRECISION.
     */
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

    /**
     * Gets all the targets by a given tag.
     * 
     * @param _tag tag name to get the targets.
     */
    function getTargetsByTag(bytes32 _tag) external view override returns (address[] memory targets) {
        targets = targetsByTag[_tag].values();
    }

    /**
     * Gets all the networks where a given target is located.
     * 
     * @param _target target address to get the networks.
     */
    function getNetworksByTarget(address _target) external view override returns (uint256[] memory networks) {
        networks = networksByTarget[_target].values();
    }

    /**
     * Gets the packed score for a given target and network.
     * 
     * @param _network network id where the target is located.
     * @param _target target address to get the tags.
     */
    function getScoresByTarget(uint256 _network, address _target) external view override returns (uint128) {
        return scoresByTarget[_network][_target];
    }

    /** Internal Functions */

    /**
     * Sets a score to a target in a given network.
     * 
     * @dev target must not be empty.
     * @dev score must be greater than 0.
     * @param _network network id where the target is located.
     * @param target target address to set the score.
     * @param score score to set to the target.
     */
    function _setScore(uint256 _network, address target, uint128 score) internal {
        require(target != address(0x0), "!target");
        require(score > 0, "!score");

        scoresByTarget[_network][target] = score;
        _addNetworkInTargetIfNeeded(_network, target);

        emit ScoreSet(_network, target, score);
    }

    /**
     * Sets a tags list to a target located in a given network.
     * 
     * @dev target must not be empty.
     * @dev tags list must not be empty.
     * @param _network network id where the target is located.
     * @param target target address to set the tags.
     * @param tagsList list of tags to set to the target.
     */
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

            emit TagSet(_network, target, tag);
        }
    }

    /**
     * Adds a network to a target only if it's not already added.
     * 
     * @param _network network id where the target is located.
     * @param _target target address to add the network.
     */
    function _addNetworkInTargetIfNeeded(uint256 _network, address _target) internal {
        if (networksByTarget[_target].contains(_network) == false) {
            networksByTarget[_target].add(_network);
        }
    }

    /**
     * Removes a list of tags from a target located in a given network.
     * 
     * @param _network network id where the target is located.
     * @param target target address to remove the tags.
     * @param tagsList list of tags to remove from the target.
     */
    function _removeTags(uint256 _network, address target, bytes32[] calldata tagsList) internal {
        require(target != address(0x0), "!target");
        require(tagsList.length > 0, "!tags_list");

        for (uint256 index = 0; index < tagsList.length; ++index) {
            bytes32 tag = tagsList[index];
            require(tag != "", "!tag_empty");

            require(tagsByTarget[_network][target].remove(tag) == true, "!tag_removed");
            require(targetsByTag[tag].remove(target) == true, "!target_removed");

            emit TagRemoved(_network, target, tag);
        }
    }
}
