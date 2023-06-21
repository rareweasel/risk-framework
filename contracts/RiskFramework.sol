// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libs/ScoresLib.sol";
import "./interfaces/yearn/v3/IOracle.sol";
import "./interfaces/IRiskFramework.sol";

contract RiskFramework is IRiskFramework, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ScoresLib for *;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    uint256 public override constant AVERAGE_PRECISION = 1000;
    
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

    // Target => list of tags
    mapping(address => EnumerableSet.Bytes32Set) internal tagsByTarget;

    // Target => scores
    mapping(address => uint128) public override scoresByTarget;

    /**
        Current available scores
     */
    uint256 public override currentScores;

    constructor(
        address initialOwnerAddress,
        address initialConfiguratorAddress,
        address initialAdminAddress,
        uint256 initialCurrentScores
    ) {
        require(initialOwnerAddress != address(0), "!initial_owner");
        require(initialConfiguratorAddress != address(0), "!initial_configurator");
        require(initialAdminAddress != address(0), "!initial_admin");
        require(initialCurrentScores > 0 && initialCurrentScores <= MAX_SCORES, "!initial_scores");

        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(OWNER_ROLE, initialOwnerAddress);
        _setupRole(CONFIGURATOR_ROLE, initialConfiguratorAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, initialAdminAddress);
        currentScores = initialCurrentScores;
    }

    function setScores(address target, bytes32[] calldata tagsList, uint128 scores)
        external override
    {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!access_role");
        _setScores(target, tagsList, scores);
    }

    /** View Functions */

    function getTargetInfo(address target)
        external override view returns (uint128 scores, uint8[] memory scoresList, uint128 averageScore, bytes32[] memory tagsList)
    {
        scores = scoresByTarget[target];
        tagsList = tagsByTarget[target].values();
        (scoresList, averageScore) = getScores(scores);
    }

    function getScores(uint128 scores)
        public override view returns (uint8[] memory scoresList, uint128 averageScore)
    {
        // 5506139203, 35, 15, 5
        // Scores, total bits, start bit (rigth to left), bits per score
        // scores.getNBits(uint256 x, uint256 start, uint256 offset)
        scoresList = new uint8[](currentScores);
        uint128 totalScores;

        for (uint256 index = 0; index < currentScores; ++index) {
            uint256 startBit = (index + 1) * 5;
            uint256 score = scores.getNBits(MAX_SCORES_BITS, startBit, BITS_PER_SCORES);
            totalScores += uint8(score);
            scoresList[currentScores - index - 1] = uint8(score);
        }
        averageScore = uint128(totalScores * AVERAGE_PRECISION / currentScores);
    }

    /** Internal Functions */

    function _setScores(address target, bytes32[] calldata tagsList, uint128 scores)
        internal
    {
        require(target != address(0x0), "!target");
        require(tagsList.length > 0, "!tags_list");
        require(scores > 0, "!scores"); // TODO Verify each score is > 0?

        for (uint256 index = 0; index < tagsList.length; ++index) {
            bytes32 tag = tagsList[index];
            require(tag != "", "!tag");
            require(tagsByTarget[target].contains(tag) == false, "!tag_already_set");
            require(targetsByTag[tag].contains(target) == false, "!target_already_set");
            targetsByTag[tag].add(target);
            tagsByTarget[target].add(tag);
        }
        scoresByTarget[target] = scores;

        emit TargetScored(target, tagsList, scores);
    }
}

