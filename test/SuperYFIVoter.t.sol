// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {console2 as console} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC20PresetFixedSupply} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {SuperYFIVoter} from "../src/SuperYFIVoter.sol";
import {MockVotingToken} from "./mocks/MockVotingToken.sol";

contract SuperYFIVoterTest is PRBTest, StdCheats {
    SuperYFIVoter internal voter;
    ERC20PresetFixedSupply internal lockToken;
    MockVotingToken internal ve;
    address internal gov = address(1);
    address internal strategy = address(2);
    address internal newGov = address(3);
    address internal receiver = address(4);

    uint256 public constant MAX_SUPPLY = 100000000000000000000000000;

    function setUp() public {
        hoax(gov);
        lockToken = new ERC20PresetFixedSupply("LockToken", "LT", MAX_SUPPLY, gov);
        ve = new MockVotingToken();
        voter = new SuperYFIVoter(gov, address(ve), address(lockToken), "SuperYFIVoter");

        hoax(gov);
        voter.setStrategy(strategy);

        vm.label(address(lockToken), "LockToken");
        vm.label(address(ve), "VE");
        vm.label(address(voter), "Voter");
        vm.label(address(strategy), "Strategy");
        vm.label(address(gov), "Gov");
    }

    function test_setUp() public {
        assertEq(voter.governance(), gov);
        assertEq(voter.ve(), address(ve));
        assertEq(voter.token(), address(lockToken));
        assertEq(voter.name(), "SuperYFIVoter");
        assertEq(voter.strategy(), strategy);
    }

    function test_constructor_revertIfgovIsZero() public {
        vm.expectRevert(bytes("!gov"));

        new SuperYFIVoter(address(0), address(ve), address(lockToken), "SuperYFIVoter");
    }

    function test_constructor_revertIfveContractIsZero() public {
        vm.expectRevert(bytes("!ve"));

        new SuperYFIVoter(gov, address(0), address(lockToken), "SuperYFIVoter");
    }

    function test_constructor_revertIfLockTokenIsZero() public {
        vm.expectRevert(bytes("!tokenToLock"));

        new SuperYFIVoter(gov, address(ve), address(0), "SuperYFIVoter");
    }

    function test_createLock_expectRevertIfNotAuthorized(address _random, uint256 _amount, uint256 _unlockTime) public {
        vm.assume(_random != gov && _random != strategy);
        vm.expectRevert(bytes("!authorized"));

        hoax(_random);
        voter.createLock(_amount, _unlockTime);
    }

    function test_createLock_expectCorrectLockAmountAndUnlockTime(uint256 _amount, uint256 _unlockTime) public {
        // checks mock call args are correct
        vm.expectCall(address(ve), abi.encodeCall(ve.modify_lock, (_amount, _unlockTime)));

        hoax(gov);
        voter.createLock(_amount, _unlockTime);
    }

    function test_increaseAmount_expectRevertIfNotAuthorized(address _random, uint256 _amount) public {
        vm.assume(_random != gov && _random != strategy);
        vm.expectRevert(bytes("!authorized"));

        hoax(_random);
        voter.increaseAmount(_amount);
    }

    function test_increaseAmount_expectCorrectAmount(uint256 _amount) public {
        // checks mock call args are correct
        vm.expectCall(address(ve), abi.encodeCall(ve.modify_lock, (_amount, 0)));

        hoax(gov);
        voter.increaseAmount(_amount);
    }

    function test_extendUnlockTime_expectRevertIfNotAuthorized(address _random, uint256 _unlockTime) public {
        vm.assume(_random != gov && _random != strategy);
        vm.expectRevert(bytes("!authorized"));

        hoax(_random);
        voter.extendUnlockTime(_unlockTime);
    }

    function test_extendUnlockTime_expectCorrectTime(uint256 _unlockTime) public {
        // checks mock call args are correct
        vm.expectCall(address(ve), abi.encodeCall(ve.modify_lock, (0, _unlockTime)));

        hoax(gov);
        voter.extendUnlockTime(_unlockTime);
    }

    function test_release_expectRevertIfNotAuthorized(address _random) public {
        vm.assume(_random != gov && _random != strategy);
        vm.expectRevert(bytes("!authorized"));

        hoax(_random);
        voter.release();
    }

    function test_release_expectVeCorrectlyCalled() public {
        // checks mock call args are correct
        vm.expectCall(address(ve), abi.encodeCall(ve.withdraw, ()));

        hoax(gov);
        voter.release();
    }

    function test_setStrategy_expectRevertIfNotAuthorized(address _random, address _newStrategy) public {
        vm.assume(_random != gov);
        vm.expectRevert(bytes("!gov"));

        hoax(_random);
        voter.setStrategy(_newStrategy);
    }

    function test_setStrategy_worksCorrectly(address _newStrategy) public {
        hoax(gov);
        voter.setStrategy(_newStrategy);

        assertEq(voter.strategy(), _newStrategy);
    }

    function test_setPendingGovernance_expectRevertIfNotAuthorized(address _random, address _newGovernance) public {
        vm.assume(_random != gov);
        vm.expectRevert(bytes("!gov"));

        hoax(_random);
        voter.setPendingGovernance(_newGovernance);
    }

    function test_acceptGovernance_expectRevertIfNotCorrectAddress(address _random) public {
        vm.assume(_random != gov && _random != newGov);

        hoax(gov);
        voter.setPendingGovernance(newGov);

        vm.expectRevert(bytes("!pendingGov"));

        hoax(_random);
        voter.acceptGovernance();
    }

    function test_acceptGovernance_ChangedCorrectly() public {
        hoax(gov);
        voter.setPendingGovernance(newGov);

        hoax(newGov);
        voter.acceptGovernance();

        assertEq(voter.governance(), newGov);
    }

    function test_execute_expectRevertIfNotAuthorized(
        address _random,
        address _target,
        uint256 _value,
        bytes memory _data
    ) public {
        vm.assume(_random != gov && _random != strategy);
        vm.expectRevert(bytes("!authorized"));

        hoax(_random);
        voter.execute(payable(_target), _value, _data);
    }

    function test_execute_shouldTransferTokens(uint256 _initialBalance, uint256 _transferAmount) public {
        vm.assume(_initialBalance > 10000 && _initialBalance < MAX_SUPPLY);
        vm.assume(_initialBalance >= _transferAmount);
        vm.assume(_transferAmount > 0);
        deal(address(lockToken), address(voter), _initialBalance);

        assertEq(lockToken.balanceOf(address(voter)), _initialBalance);
        assertEq(lockToken.balanceOf(receiver), 0);

        hoax(gov);
        voter.execute(payable(address(lockToken)), 0, abi.encodeCall(lockToken.transfer, (receiver, _transferAmount)));

        assertEq(lockToken.balanceOf(address(voter)), _initialBalance - _transferAmount);

        assertEq(lockToken.balanceOf(receiver), _transferAmount);
    }
}
