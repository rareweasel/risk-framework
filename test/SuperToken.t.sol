// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC20PresetFixedSupply} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {SuperToken} from "../src/SuperToken.sol";

contract SuperTokenTest is PRBTest, StdCheats {
    SuperToken internal superToken;
    address internal owner;
    ERC20PresetFixedSupply internal lockToken;
    ERC20PresetFixedSupply internal extraToken;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        owner = address(1);
        hoax(owner);
        lockToken = new ERC20PresetFixedSupply("LockToken", "LT", 100000000000000000000000000, owner);
        extraToken = new ERC20PresetFixedSupply("ExtraToken", "ET", 100000000000000000000000000, owner);
        address voter = address(2);
        address sweepRecipient = address(3);
        superToken = new SuperToken("SuperToken", "ST", address(lockToken), voter, sweepRecipient);

        vm.label(address(lockToken), "LockToken");
        vm.label(address(extraToken), "ExtraToken");
        vm.label(voter, "Voter");
        vm.label(sweepRecipient, "SweepRecipient");
    }

    function testContract_setUp_successful(address _lockToken, address _voter, address _sweepRecipient) external {
        vm.assume(_lockToken != address(0x0));
        vm.assume(_voter != address(0x0));
        vm.assume(_sweepRecipient != address(0x0));
        SuperToken token = new SuperToken("SuperToken", "ST", _lockToken, _voter, _sweepRecipient);

        assertEq(token.sweepRecipient(), _sweepRecipient, "invalid sweep recipient");
        assertEq(token.LOCK_TOKEN(), _lockToken, "invalid lock token");
        assertEq(token.VOTER(), _voter, "invalid voter");
    }

    function testContract_setUp_invalidLockToken(address _voter, address _sweepRecipient) external {
        vm.assume(_voter != address(0x0));
        vm.assume(_sweepRecipient != address(0x0));
        vm.expectRevert("!lock_token");
        new SuperToken("SuperToken", "ST", address(0x0), _voter, _sweepRecipient);
    }

    function testContract_setUp_invalidVoter(address _lockToken, address _sweepRecipient) external {
        vm.assume(_lockToken != address(0x0));
        vm.assume(_sweepRecipient != address(0x0));
        vm.expectRevert("!voter");
        new SuperToken("SuperToken", "ST", _lockToken, address(0x0), _sweepRecipient);
    }

    function testContract_setUp_invalidSweepRecipient(address _lockToken, address _voter) external {
        vm.assume(_lockToken != address(0x0));
        vm.assume(_voter != address(0x0));
        vm.expectRevert("!sweep_recipient");
        new SuperToken("SuperToken", "ST", _lockToken, _voter, address(0x0));
    }

    function test_mintAmountAndRecipient_successful(uint256 _minterBalance, uint256 _amountToMint) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToMint > 0);
        vm.assume(_minterBalance >= _amountToMint);
        address minter = address(4);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.approve(address(superToken), _amountToMint);
        hoax(minter);
        superToken.mint(_amountToMint, minter);

        assertEq(superToken.balanceOf(minter), _amountToMint, "invalid super token balance");
        assertEq(lockToken.balanceOf(minter), _minterBalance - _amountToMint, "invalid lock token balance");
    }

    function test_mintAmountAndRecipient_successful_another_recipient(
        uint256 _minterBalance,
        uint256 _amountToMint,
        address _recipient
    ) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToMint > 0);
        vm.assume(_minterBalance >= _amountToMint);
        vm.assume(_recipient != address(0x0));
        vm.assume(_recipient != address(superToken));

        address minter = address(4);
        vm.assume(_recipient != minter);

        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.approve(address(superToken), _amountToMint);
        hoax(minter);
        superToken.mint(_amountToMint, _recipient);

        assertEq(superToken.balanceOf(_recipient), _amountToMint, "recipient: invalid super token balance");
        assertEq(superToken.balanceOf(minter), 0, "minter: invalid super token balance");
        assertEq(lockToken.balanceOf(minter), _minterBalance - _amountToMint, "minter: invalid lock token balance");
    }

    function test_mintAmountAndRecipient_invalidMintToSelf(uint256 _minterBalance, uint256 _amountToMint) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToMint > 0);
        vm.assume(_minterBalance >= _amountToMint);
        address minter = address(superToken);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.approve(address(superToken), _amountToMint);

        vm.expectRevert("SuperToken: mint to self");
        hoax(minter);
        superToken.mint(_amountToMint, minter);

        assertEq(superToken.balanceOf(minter), 0, "invalid super token balance");
        assertEq(lockToken.balanceOf(minter), _minterBalance, "invalid lock token balance");
    }

    function test_mintAmountAndRecipient_invalidMintZeroAmount(address _minter, uint256 _minterBalance) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_minter != address(0x0));
        vm.assume(_minter != address(superToken));
        uint256 amountToMint = 0;

        deal(address(lockToken), _minter, _minterBalance);
        assertTrue(lockToken.balanceOf(_minter) == _minterBalance, "invalid minter balance");

        hoax(_minter);
        lockToken.approve(address(superToken), amountToMint);

        vm.expectRevert("SuperToken: mint zero");
        hoax(_minter);
        superToken.mint(amountToMint, _minter);

        assertEq(superToken.balanceOf(_minter), 0, "invalid super token balance");
        assertEq(lockToken.balanceOf(_minter), _minterBalance, "invalid lock token balance");
    }

    function test_mintAmountAndRecipient_invalidMaxWithoutBalance(address _minter, uint256 amountToMint) external {
        vm.assume(_minter != address(0x0));
        vm.assume(_minter != owner);
        vm.assume(_minter != address(superToken));
        vm.assume(amountToMint > 0);
        assertTrue(lockToken.balanceOf(_minter) == 0, "invalid minter balance");

        vm.expectRevert("SuperToken: mint zero");
        hoax(_minter);
        superToken.mint(type(uint256).max, _minter);

        assertEq(superToken.balanceOf(_minter), 0, "invalid super token balance");
        assertEq(lockToken.balanceOf(_minter), 0, "invalid lock token balance");
    }

    function test_mintAmountAndRecipient_maxWithBalance(address _minter, uint256 _minterBalance) external {
        vm.assume(_minter != address(0x0));
        vm.assume(_minter != address(superToken));
        vm.assume(_minter != owner);
        vm.assume(_minter != superToken.VOTER());
        vm.assume(_minterBalance > 0);
        deal(address(lockToken), _minter, _minterBalance);
        assertTrue(lockToken.balanceOf(_minter) == _minterBalance, "invalid minter balance");

        hoax(_minter);
        lockToken.approve(address(superToken), type(uint256).max);

        hoax(_minter);
        superToken.mint(type(uint256).max, _minter);

        assertEq(superToken.balanceOf(_minter), _minterBalance, "invalid super token balance");
        assertEq(lockToken.balanceOf(_minter), 0, "invalid lock token balance");
    }

    function test_mintAmount_successful(uint256 _minterBalance, uint256 _amountToMint) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToMint > 0);
        vm.assume(_minterBalance >= _amountToMint);
        address minter = address(4);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.approve(address(superToken), _amountToMint);
        hoax(minter);
        superToken.mint(_amountToMint);

        assertEq(superToken.balanceOf(minter), _amountToMint, "invalid super token balance");
        assertEq(lockToken.balanceOf(minter), _minterBalance - _amountToMint, "invalid lock token balance");
    }

    function test_mint_successful(uint256 _minterBalance) external {
        vm.assume(_minterBalance > 0);
        address minter = address(4);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.approve(address(superToken), _minterBalance);
        hoax(minter);
        superToken.mint();

        assertEq(superToken.balanceOf(minter), _minterBalance, "invalid super token balance");
        assertEq(lockToken.balanceOf(minter), 0, "invalid lock token balance");
    }

    function test_sweepToken_successful(uint256 _minterBalance, uint256 _amountToTransfer) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToTransfer > 0);
        vm.assume(_minterBalance >= _amountToTransfer);

        address sweepRecipient = superToken.sweepRecipient();

        address minter = address(4);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.transfer(address(superToken), _amountToTransfer);

        hoax(sweepRecipient);
        superToken.sweep(address(lockToken));

        assertEq(lockToken.balanceOf(sweepRecipient), _amountToTransfer, "sweep recipient: invalid lock token balance");
        assertEq(lockToken.balanceOf(address(superToken)), 0, "super token: invalid lock token balance");
    }

    function test_sweepToken_withoutBalance() external {
        address sweepRecipient = superToken.sweepRecipient();

        vm.expectRevert("SuperToken: sweep zero");
        hoax(sweepRecipient);
        superToken.sweep(address(lockToken));

        assertEq(lockToken.balanceOf(sweepRecipient), 0, "sweep recipient: invalid lock token balance");
        assertEq(lockToken.balanceOf(address(superToken)), 0, "super token: invalid lock token balance");
    }

    function test_sweepToken_invalidRecipient(address _sweepRecipient) external {
        address sweepRecipient = superToken.sweepRecipient();
        vm.assume(sweepRecipient != _sweepRecipient);
        vm.assume(_sweepRecipient != owner);
        vm.assume(_sweepRecipient != address(0x0));

        vm.expectRevert("SuperToken: not sweep recipient");
        hoax(_sweepRecipient);
        superToken.sweep(address(lockToken));

        assertEq(lockToken.balanceOf(sweepRecipient), 0, "sweep recipient: invalid lock token balance");
        assertEq(lockToken.balanceOf(address(superToken)), 0, "super token: invalid lock token balance");
        assertEq(lockToken.balanceOf(_sweepRecipient), 0, "sweep recipient (param): invalid lock token balance");
    }

    function test_sweepTokenAndAmount_successful(
        uint256 _minterBalance,
        uint256 _amountToTransfer,
        uint256 _amountToSweep
    ) external {
        vm.assume(_minterBalance > 0);
        vm.assume(_amountToTransfer > 0);
        vm.assume(_amountToSweep > 0);
        vm.assume(_minterBalance >= _amountToTransfer);
        vm.assume(_amountToTransfer >= _amountToSweep);

        address sweepRecipient = superToken.sweepRecipient();

        address minter = address(4);
        deal(address(lockToken), minter, _minterBalance);
        assertTrue(lockToken.balanceOf(minter) == _minterBalance, "invalid minter balance");

        hoax(minter);
        lockToken.transfer(address(superToken), _amountToTransfer);

        hoax(sweepRecipient);
        superToken.sweep(address(lockToken), _amountToSweep);

        assertEq(lockToken.balanceOf(sweepRecipient), _amountToSweep, "sweep recipient: invalid lock token balance");
        assertEq(
            lockToken.balanceOf(address(superToken)),
            _amountToTransfer - _amountToSweep,
            "super token: invalid lock token balance"
        );
    }

    function test_setSweepRecipient_successful(address _newSweepRecipient) external {
        address sweepRecipient = superToken.sweepRecipient();
        vm.assume(sweepRecipient != _newSweepRecipient);
        vm.assume(_newSweepRecipient != address(0x0));

        hoax(sweepRecipient);
        superToken.setSweepRecipient(_newSweepRecipient);

        assertEq(superToken.sweepRecipient(), _newSweepRecipient, "invalid sweep recipient");
    }

    function test_setSweepRecipient_invalidSender(address _currentSweepRecipient, address _newSweepRecipient) external {
        address sweepRecipient = superToken.sweepRecipient();
        vm.assume(sweepRecipient != _currentSweepRecipient);
        vm.assume(_newSweepRecipient != address(0x0));

        vm.expectRevert("SuperToken: not sweep recipient");
        hoax(_currentSweepRecipient);
        superToken.setSweepRecipient(_newSweepRecipient);

        assertEq(superToken.sweepRecipient(), sweepRecipient, "invalid sweep recipient");
    }
}
