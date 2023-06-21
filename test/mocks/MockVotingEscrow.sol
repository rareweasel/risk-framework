// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "../../src/interfaces/yearn/IVotingEscrow.sol";

contract MockVotingEscrow is ERC20PresetFixedSupply, IVotingEscrow {
    LockedBalance internal _locked;

    constructor() ERC20PresetFixedSupply("MockVotingEscrow", "MVS", 900000000 * 10 ** 18, msg.sender) {}

    function locked(address) external view returns (LockedBalance memory) {
        return _locked;
    }

    function modify_lock(uint256, uint256) external {}

    function withdraw() external {}

    function setLocked(int128 _amount, uint256 _end) external {
        _locked = LockedBalance(_amount, _end);
    }
}
