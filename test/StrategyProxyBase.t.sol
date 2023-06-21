// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {StrategyProxyAsserts} from "./utils/StrategyProxyAsserts.sol";
import {StrategyProxyBase} from "../src/StrategyProxyBase.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MockProxyVoter} from "./mocks/MockProxyVoter.sol";
import {MockVotingEscrow} from "./mocks/MockVotingEscrow.sol";
import {MockTokensValidator} from "./mocks/MockTokensValidator.sol";
import {IProxy} from "../src/interfaces/yearn/IProxy.sol";

contract StrategyProxyBaseTest is StrategyProxyAsserts {
    uint32 internal constant DEFAULT_MAX_LOCK_YEARS = 4;
    bool internal constant NOT_ADD = false;
    bool internal constant ADD = true;

    StrategyProxyBase internal proxy;
    address internal lockToken;
    address internal lockTokenOwner;
    address internal proxyVoter;
    address internal votingEscrow;
    address internal tokensValidator;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        address factory = address(1);
        address governance = address(2);
        address claimer = address(3);
        proxyVoter = address(new MockProxyVoter());
        lockTokenOwner = address(100);
        hoax(lockTokenOwner);
        lockToken = address(new MockToken());
        address rewardToken = address(6);
        votingEscrow = address(new MockVotingEscrow());
        tokensValidator = address(new MockTokensValidator());

        hoax(governance);
        proxy = new StrategyProxyBase(
            factory,
            governance,
            claimer,
            proxyVoter,
            lockToken,
            rewardToken,
            votingEscrow,
            tokensValidator,
            DEFAULT_MAX_LOCK_YEARS
        );

        address[] memory rewardPools = new address[](2);
        rewardPools[0] = address(11);
        rewardPools[1] = address(12);
        hoax(governance);
        proxy.updateRewardPools(rewardPools, true);

        vm.label(address(proxy), "StrategyProxyBase");
        vm.label(factory, "Factory");
        vm.label(claimer, "FeeRecipient");
        vm.label(governance, "Governance");
        vm.label(proxyVoter, "ProxyVoter");
        vm.label(lockToken, "LockToken");
        vm.label(rewardToken, "RewardToken");
        vm.label(votingEscrow, "VotingEscrow");
        vm.label(tokensValidator, "TokensValidator");
        vm.label(rewardPools[0], "RewardPool[0]");
        vm.label(rewardPools[1], "RewardPool[1]");
    }

    function test_constructor_successful(
        address _factory,
        address _governance,
        address _claimer,
        address _proxyVoter,
        address _lockToken,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        vm.assume(_factory != address(0x0));
        vm.assume(_governance != address(0x0));
        vm.assume(_claimer != address(0x0));
        vm.assume(_proxyVoter != address(0x0));
        vm.assume(_lockToken != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);

        hoax(_governance);
        StrategyProxyBase proxyBase = new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _proxyVoter,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );

        assertEq(proxyBase.factory(), _factory, "invalid factory");
        assertEq(proxyBase.claimer(), _claimer, "invalid claimer");
        assertEq(proxyBase.governance(), _governance, "invalid governance");
        assertEq(proxyBase.VOTER(), _proxyVoter, "invalid proxy voter");
        assertEq(proxyBase.LOCK_TOKEN(), _lockToken, "invalid lock token");
        assertEq(proxyBase.REWARD_TOKEN(), _rewardToken, "invalid reward token");
        assertEq(proxyBase.VOTING_ESCROW(), _votingEscrow, "invalid voting escrow");
        assertEq(proxyBase.tokensValidator(), _tokensValidator, "invalid tokens validator");
    }

    function test_constructor_invalidFactory(
        address _governance,
        address _claimer,
        address _proxyVoter,
        address _lockToken,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        address _factory = address(0x0);
        vm.assume(_governance != address(0x0));
        vm.assume(_claimer != address(0x0));
        vm.assume(_proxyVoter != address(0x0));
        vm.assume(_lockToken != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);

        hoax(_governance);
        vm.expectRevert("!factory");
        new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _proxyVoter,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );
    }

    function test_constructor_invalidGovernance(
        address _factory,
        address _claimer,
        address _proxyVoter,
        address _lockToken,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        vm.assume(_factory != address(0x0));
        vm.assume(_proxyVoter != address(0x0));
        address _governance = address(0x0);
        vm.assume(_claimer != address(0x0));
        vm.assume(_lockToken != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);

        hoax(_governance);
        vm.expectRevert("!governance");
        new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _proxyVoter,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );
    }

    function test_constructor_invalidFeeRecipient(
        address _factory,
        address _governance,
        address _proxyVoter,
        address _lockToken,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        vm.assume(_factory != address(0x0));
        vm.assume(_governance != address(0x0));
        vm.assume(_proxyVoter != address(0x0));
        vm.assume(_lockToken != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);
        address _claimer = address(0x0);

        hoax(_governance);
        vm.expectRevert("!claimer");
        new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _proxyVoter,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );
    }

    function test_constructor_invalidProxyVoter(
        address _factory,
        address _governance,
        address _claimer,
        address _lockToken,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        vm.assume(_factory != address(0x0));
        vm.assume(_governance != address(0x0));
        vm.assume(_claimer != address(0x0));
        vm.assume(_lockToken != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);
        address _voterProxy = address(0x0);

        hoax(_governance);
        vm.expectRevert("!voter_proxy");
        new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _voterProxy,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );
    }

    function test_constructor_invalidLockToken(
        address _factory,
        address _governance,
        address _claimer,
        address _proxyVoter,
        address _rewardToken,
        address _votingEscrow,
        address _tokensValidator,
        uint32 _maxLockYears
    ) external {
        vm.assume(_factory != address(0x0));
        vm.assume(_governance != address(0x0));
        vm.assume(_claimer != address(0x0));
        vm.assume(_proxyVoter != address(0x0));
        vm.assume(_rewardToken != address(0x0));
        vm.assume(_votingEscrow != address(0x0));
        vm.assume(_tokensValidator != address(0x0));
        vm.assume(_maxLockYears > 0);
        address _lockToken = address(0x0);

        hoax(_governance);
        vm.expectRevert("!lock_token");
        new StrategyProxyBase(
            _factory,
            _governance,
            _claimer,
            _proxyVoter,
            _lockToken,
            _rewardToken,
            _votingEscrow,
            _tokensValidator,
            _maxLockYears
        );
    }

    function test_setFactory_successful(address _newFactory) external {
        vm.assume(_newFactory != proxy.factory());

        hoax(proxy.governance());
        proxy.setFactory(_newFactory);

        assertEq(proxy.factory(), _newFactory, "invalid factory");
    }

    function test_setFactory_invalidSameFactory(address _newFactory) external {
        vm.assume(_newFactory != proxy.factory());

        hoax(proxy.governance());
        proxy.setFactory(_newFactory);
        assertEq(proxy.factory(), _newFactory, "invalid factory");

        hoax(proxy.governance());
        vm.expectRevert("already set");
        proxy.setFactory(_newFactory);

        assertEq(proxy.factory(), _newFactory, "invalid factory");
    }

    function test_setFactory_invalidGovernance(address _governance, address _newFactory) external {
        vm.assume(_newFactory != address(0x0));
        vm.assume(_governance != proxy.governance());
        address factory = proxy.factory();

        hoax(_governance);
        vm.expectRevert("!governance");
        proxy.setFactory(_newFactory);

        assertEq(proxy.factory(), factory, "invalid factory");
    }

    function test_setClaimer_successful(address _newFeeRecipient) external {
        vm.assume(_newFeeRecipient != address(0x0));
        vm.assume(_newFeeRecipient != proxy.claimer());

        hoax(proxy.governance());
        proxy.setClaimer(_newFeeRecipient);

        assertEq(proxy.claimer(), _newFeeRecipient, "invalid claimer");
    }

    function test_setClaimer_invalidAddress() external {
        address _newFeeRecipient = address(0x0);
        address feeRecipient = proxy.claimer();

        hoax(proxy.governance());
        vm.expectRevert("!zeroaddress");
        proxy.setClaimer(_newFeeRecipient);

        assertEq(feeRecipient, proxy.claimer(), "invalid claimer");
    }

    function test_setClaimer_invalidGovernance(address _governance, address _newFeeRecipient) external {
        vm.assume(_newFeeRecipient != address(0x0));
        vm.assume(_governance != proxy.governance());
        address feeRecipient = proxy.claimer();

        hoax(_governance);
        vm.expectRevert("!governance");
        proxy.setClaimer(_newFeeRecipient);

        assertEq(proxy.claimer(), feeRecipient, "invalid claimer");
    }

    function test_setClaimer_invalidSameFeeRecipient(address _newFeeRecipient) external {
        vm.assume(_newFeeRecipient != address(0x0));
        vm.assume(_newFeeRecipient != proxy.factory());
        vm.assume(_newFeeRecipient != proxy.claimer());

        hoax(proxy.governance());
        proxy.setClaimer(_newFeeRecipient);
        assertEq(proxy.claimer(), _newFeeRecipient, "invalid claimer");

        hoax(proxy.governance());
        vm.expectRevert("already set");
        proxy.setClaimer(_newFeeRecipient);

        assertEq(proxy.claimer(), _newFeeRecipient, "invalid claimer");
    }

    function test_approveStrategy_successful(bool _useGovernance, address _gauge, address _strategy) external {
        address _governanceOrFactory = _useGovernance ? proxy.governance() : proxy.factory();
        vm.assume(_gauge != address(0x0));
        vm.assume(_strategy != address(0x0));

        hoax(_governanceOrFactory);
        proxy.approveStrategy(_gauge, _strategy);

        assertEq(proxy.strategies(_gauge), _strategy, "invalid strategy");
    }

    function test_approveStrategy_invalidStrategyZero(bool _useGovernance, address _gauge) external {
        address _governanceOrFactory = _useGovernance ? proxy.governance() : proxy.factory();
        vm.assume(_gauge != address(0x0));
        address _strategy = address(0x0);

        hoax(_governanceOrFactory);
        vm.expectRevert("!strategy_zero");
        proxy.approveStrategy(_gauge, _strategy);

        assertEq(proxy.strategies(_gauge), address(0x0), "invalid strategy");
    }

    function test_approveStrategy_invalidGaugeZero(bool _useGovernance, address _strategy) external {
        address _governanceOrFactory = _useGovernance ? proxy.governance() : proxy.factory();
        vm.assume(_strategy != address(0x0));
        address _gauge = address(0x0);

        hoax(_governanceOrFactory);
        vm.expectRevert("!gauge_zero");
        proxy.approveStrategy(_gauge, _strategy);

        assertEq(proxy.strategies(_gauge), address(0x0), "invalid strategy");
    }

    function test_approveStrategy_invalidGovernanceOrFactory(
        address _governanceOrFactory,
        address _gauge,
        address _strategy
    ) external {
        vm.assume(_governanceOrFactory != proxy.governance() && _governanceOrFactory != proxy.factory());
        vm.assume(_gauge != address(0x0));
        vm.assume(_strategy != address(0x0));

        hoax(_governanceOrFactory);
        vm.expectRevert("!access");
        proxy.approveStrategy(_gauge, _strategy);

        assertEq(proxy.strategies(_gauge), address(0x0), "invalid strategy");
    }

    function test_approveStrategy_invalidGaugeAlreadySet(
        bool _useGovernance,
        address _gauge,
        address _strategy
    ) external {
        address _governanceOrFactory = _useGovernance ? proxy.governance() : proxy.factory();
        vm.assume(_gauge != address(0x0));
        vm.assume(_strategy != address(0x0));

        hoax(_governanceOrFactory);
        proxy.approveStrategy(_gauge, _strategy);

        hoax(_governanceOrFactory);
        vm.expectRevert("already approved");
        proxy.approveStrategy(_gauge, _strategy);

        assertEq(proxy.strategies(_gauge), _strategy, "invalid strategy");
    }

    function test_approveLocker_successful(address _locker) external {
        address _governance = proxy.governance();
        vm.assume(_locker != address(0x0));

        hoax(_governance);
        proxy.approveLocker(_locker);

        assertEq(proxy.lockers(_locker), true, "invalid locker");
    }

    function test_approveLocker_invalidLockerZero() external {
        address _locker = address(0x0);
        address _governance = proxy.governance();

        hoax(_governance);
        vm.expectRevert("!locker");
        proxy.approveLocker(_locker);

        assertEq(proxy.lockers(_locker), false, "invalid locker");
    }

    function test_approveLocker_alreadySet(address _locker) external {
        address _governance = proxy.governance();
        vm.assume(_locker != address(0x0));

        hoax(_governance);
        proxy.approveLocker(_locker);

        hoax(_governance);
        vm.expectRevert("already approved");
        proxy.approveLocker(_locker);

        assertEq(proxy.lockers(_locker), true, "invalid locker");
    }

    function test_approveLocker_invalidSender(address _locker, address _sender) external {
        vm.assume(_locker != address(0x0));
        vm.assume(_sender != address(0x0) && _sender != proxy.governance());

        hoax(_sender);
        vm.expectRevert("!governance");
        proxy.approveLocker(_locker);

        assertEq(proxy.lockers(_locker), false, "invalid locker");
    }

    function test_revokeLocker_successful(address _locker) external {
        address _governance = proxy.governance();
        vm.assume(_locker != address(0x0));

        hoax(_governance);
        proxy.approveLocker(_locker);

        hoax(_governance);
        proxy.revokeLocker(_locker);

        assertEq(proxy.lockers(_locker), false, "invalid locker");
    }

    function test_revokeLocker_invalid_lockerNonApproved(address _locker) external {
        address _governance = proxy.governance();
        // vm.assume(_locker != address(0x0));

        hoax(_governance);
        vm.expectRevert("already revoked");
        proxy.revokeLocker(_locker);

        assertEq(proxy.lockers(_locker), false, "invalid locker");
    }

    function test_revokeLocker_invalidSender(address _locker, address _sender) external {
        address governance = proxy.governance();
        vm.assume(_locker != address(0x0));
        vm.assume(_sender != address(0x0) && _sender != governance);

        hoax(governance);
        proxy.approveLocker(_locker);

        hoax(_sender);
        vm.expectRevert("!governance");
        proxy.revokeLocker(_locker);

        assertEq(proxy.lockers(_locker), true, "invalid locker");
    }

    function test_revokeStrategy_successful(address _gauge, address _strategy) external {
        address _governance = proxy.governance();
        vm.assume(_strategy != address(0x0));
        vm.assume(_gauge != address(0x0));

        hoax(_governance);
        proxy.approveStrategy(_gauge, _strategy);

        hoax(_governance);
        proxy.revokeStrategy(_gauge);

        assertEq(proxy.strategies(_gauge), address(0x0), "invalid gauge");
    }

    function test_revokeStrategy_invalid_nonApproved(address _gauge) external {
        address _governance = proxy.governance();
        vm.assume(_gauge != address(0x0));

        hoax(_governance);
        vm.expectRevert("already revoked");
        proxy.revokeStrategy(_gauge);

        assertEq(proxy.strategies(_gauge), address(0x0), "invalid gauge");
    }

    function test_revokeStrategy_invalidSender(address _gauge, address _strategy, address _sender) external {
        address governance = proxy.governance();
        vm.assume(_sender != address(0x0) && _sender != governance);
        vm.assume(_strategy != address(0x0));
        vm.assume(_gauge != address(0x0));

        hoax(governance);
        proxy.approveStrategy(_gauge, _strategy);

        hoax(_sender);
        vm.expectRevert("!governance");
        proxy.revokeStrategy(_gauge);

        assertEq(proxy.strategies(_gauge), _strategy, "invalid gauge");
    }

    function test_revokeStrategy_invalidGaugeZero(address _strategy) external {
        address governance = proxy.governance();
        vm.assume(_strategy != address(0x0));
        address gauge = address(0x0);

        hoax(governance);
        // Since empty gauge returns empty strategy.
        vm.expectRevert("already revoked");
        proxy.revokeStrategy(gauge);

        assertEq(proxy.strategies(gauge), address(0x0), "invalid gauge");
    }

    function test_lock_successfull_governance(uint256 _lockTokenBalance) external {
        vm.assume(_lockTokenBalance > 0);
        address governance = proxy.governance();
        deal(address(lockToken), proxyVoter, _lockTokenBalance);
        vm.expectCall(lockToken, abi.encodeCall(MockToken(lockToken).balanceOf, (proxyVoter)));
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).increaseAmount, (_lockTokenBalance)));

        hoax(governance);
        proxy.lock();
    }

    function test_lock_invalidSender(address _governanceOrLocker, uint256 _lockTokenBalance) external {
        vm.assume(_lockTokenBalance > 0);
        vm.assume(_governanceOrLocker != proxy.governance());

        deal(address(lockToken), proxyVoter, _lockTokenBalance);
        vm.expectCall(lockToken, abi.encodeCall(MockToken(lockToken).balanceOf, (proxyVoter)), 0);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).increaseAmount, (_lockTokenBalance)), 0);

        hoax(_governanceOrLocker);
        vm.expectRevert("!locker");
        proxy.lock();
    }

    function test_lock_successful_locker(address _locker, uint256 _lockTokenBalance) external {
        vm.assume(_lockTokenBalance > 0);
        vm.assume(_locker != address(0x0));

        hoax(proxy.governance());
        proxy.approveLocker(_locker);

        deal(address(lockToken), proxyVoter, _lockTokenBalance);
        vm.expectCall(lockToken, abi.encodeCall(MockToken(lockToken).balanceOf, (proxyVoter)));
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).increaseAmount, (_lockTokenBalance)));

        hoax(_locker);
        proxy.lock();
    }

    function test_lock_successful_balance_zero(address _locker) external {
        uint256 _lockTokenBalance = 0;
        vm.assume(_locker != address(0x0));

        hoax(proxy.governance());
        proxy.approveLocker(_locker);

        vm.expectCall(lockToken, abi.encodeCall(MockToken(lockToken).balanceOf, (proxyVoter)), 1);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).increaseAmount, (_lockTokenBalance)), 0);

        hoax(_locker);
        proxy.lock();
    }

    function test_maxLock_successful_increaseTime(uint256 _lockEnd) external {
        uint256 maxLocked = proxy.getMaxLock();
        vm.assume(_lockEnd < maxLocked);
        address governance = proxy.governance();

        vm.expectCall(votingEscrow, abi.encodeCall(MockVotingEscrow(votingEscrow).locked, (proxyVoter)), 1);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).extendUnlockTime, (maxLocked)), 1);

        hoax(governance);
        proxy.maxLock();
    }

    function test_maxLock_successful_noIncreaseTime(int128 _amount, uint256 _lockEnd) external {
        uint256 maxLocked = proxy.getMaxLock();
        vm.assume(_lockEnd > maxLocked);
        address governance = proxy.governance();

        MockVotingEscrow(votingEscrow).setLocked(_amount, _lockEnd);

        vm.expectCall(votingEscrow, abi.encodeCall(MockVotingEscrow(votingEscrow).locked, (proxyVoter)), 1);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).extendUnlockTime, (maxLocked)), 0);

        hoax(governance);
        proxy.maxLock();
    }

    function test_maxLock_invalidSender(address _governanceOrLocker, int128 _amount, uint256 _lockEnd) external {
        vm.assume(_governanceOrLocker != proxy.governance());
        MockVotingEscrow(votingEscrow).setLocked(_amount, _lockEnd);
        uint256 maxLocked = proxy.getMaxLock();

        vm.expectCall(votingEscrow, abi.encodeCall(MockVotingEscrow(votingEscrow).locked, (proxyVoter)), 0);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).extendUnlockTime, (maxLocked)), 0);

        hoax(_governanceOrLocker);
        vm.expectRevert("!locker");
        proxy.maxLock();
    }

    function test_maxLock_successful_locker(address _locker, uint256 _lockEnd) external {
        vm.assume(_locker != address(0x0));
        uint256 maxLocked = proxy.getMaxLock();
        vm.assume(_lockEnd < maxLocked);
        address governance = proxy.governance();
        hoax(governance);
        proxy.approveLocker(_locker);

        vm.expectCall(votingEscrow, abi.encodeCall(MockVotingEscrow(votingEscrow).locked, (proxyVoter)), 1);
        vm.expectCall(proxyVoter, abi.encodeCall(MockProxyVoter(proxyVoter).extendUnlockTime, (maxLocked)), 1);

        hoax(_locker);
        proxy.maxLock();
    }

    function test_updateRewardPools_successful_add(uint256 _maxRewardPools) external {
        bool isAdd = true;
        vm.assume(_maxRewardPools > 0);
        vm.assume(_maxRewardPools <= proxy.MAX_REWARD_POOLS());
        address[] memory _rewardPools = new address[](_maxRewardPools);

        for (uint160 i = 0; i < _maxRewardPools; ++i) {
            _rewardPools[i] = address(i + 1);
        }

        address governance = proxy.governance();

        hoax(governance);
        proxy.updateRewardPools(_rewardPools, isAdd);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertTrue(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_add_twice_same_list() external {
        bool isAdd = true;
        address[] memory _rewardPools = new address[](3);
        _rewardPools[0] = address(0x1);
        _rewardPools[1] = address(0x2);
        _rewardPools[2] = address(0x1);

        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!reward_pool_already_added");
        proxy.updateRewardPools(_rewardPools, isAdd);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertFalse(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_add_empty_list() external {
        bool isAdd = true;
        address[] memory _rewardPools = new address[](0);

        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!reward_pools");
        proxy.updateRewardPools(_rewardPools, isAdd);
    }

    function test_updateRewardPools_invalid_add_zero_address() external {
        bool isAdd = true;
        address[] memory _rewardPools = new address[](3);
        _rewardPools[0] = address(0x1);
        _rewardPools[1] = address(0x2);
        _rewardPools[2] = address(0x0);

        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!reward_pool");
        proxy.updateRewardPools(_rewardPools, isAdd);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertFalse(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_sender_add(address _governance) external {
        vm.assume(_governance != proxy.governance());
        bool isAdd = true;
        address[] memory _rewardPools = new address[](3);
        _rewardPools[0] = address(0x1);
        _rewardPools[1] = address(0x2);
        _rewardPools[2] = address(0x3);

        hoax(_governance);
        vm.expectRevert("!governance");
        proxy.updateRewardPools(_rewardPools, isAdd);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertFalse(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_successful_not_add(uint256 _maxRewardPools) external {
        vm.assume(_maxRewardPools > 0);
        vm.assume(_maxRewardPools <= proxy.MAX_REWARD_POOLS());
        address[] memory _rewardPools = new address[](_maxRewardPools);
        for (uint160 i = 0; i < _maxRewardPools; ++i) {
            _rewardPools[i] = address(i + 1);
        }
        address governance = proxy.governance();
        hoax(governance);
        proxy.updateRewardPools(_rewardPools, ADD);

        hoax(governance);
        proxy.updateRewardPools(_rewardPools, NOT_ADD);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertFalse(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_not_add_twice_same_list() external {
        address[] memory _addRewardPools = new address[](3);
        _addRewardPools[0] = address(0x1);
        _addRewardPools[1] = address(0x2);
        _addRewardPools[2] = address(0x3);
        address[] memory _removeRewardPools = new address[](3);
        _removeRewardPools[0] = address(0x1);
        _removeRewardPools[1] = address(0x2);
        _removeRewardPools[2] = address(0x1);

        address governance = proxy.governance();
        hoax(governance);
        proxy.updateRewardPools(_addRewardPools, ADD);

        hoax(governance);
        vm.expectRevert("!reward_pool_already_removed");
        proxy.updateRewardPools(_removeRewardPools, NOT_ADD);

        for (uint160 i = 0; i < _removeRewardPools.length; ++i) {
            assertTrue(proxy.isRewardPool(_removeRewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_not_add_empty_list() external {
        address[] memory _rewardPools = new address[](0);

        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!reward_pools");
        proxy.updateRewardPools(_rewardPools, NOT_ADD);
    }

    function test_updateRewardPools_invalid_not_add_zero_address() external {
        address[] memory _addRewardPools = new address[](2);
        _addRewardPools[0] = address(0x1);
        _addRewardPools[1] = address(0x2);

        address[] memory _removeRewardPools = new address[](3);
        _removeRewardPools[0] = address(0x1);
        _removeRewardPools[1] = address(0x2);
        _removeRewardPools[2] = address(0x0);

        address governance = proxy.governance();
        hoax(governance);
        proxy.updateRewardPools(_addRewardPools, ADD);

        hoax(governance);
        vm.expectRevert("!reward_pool");
        proxy.updateRewardPools(_removeRewardPools, NOT_ADD);

        for (uint160 i = 0; i < _addRewardPools.length; ++i) {
            assertTrue(proxy.isRewardPool(_addRewardPools[i]), "invalid reward pool");
        }
    }

    function test_updateRewardPools_invalid_sender_not_add(address _governance) external {
        vm.assume(_governance != proxy.governance());
        address[] memory _rewardPools = new address[](3);
        _rewardPools[0] = address(0x1);
        _rewardPools[1] = address(0x2);
        _rewardPools[2] = address(0x3);

        hoax(_governance);
        vm.expectRevert("!governance");
        proxy.updateRewardPools(_rewardPools, NOT_ADD);

        for (uint160 i = 0; i < _rewardPools.length; ++i) {
            assertFalse(proxy.isRewardPool(_rewardPools[i]), "invalid reward pool");
        }
    }

    function test_setGovernance_successful(address _newGovernance) external {
        vm.assume(_newGovernance != proxy.governance());
        vm.assume(_newGovernance != address(0x0));

        hoax(proxy.governance());
        proxy.setGovernance(_newGovernance);

        assertEq(proxy.governance(), _newGovernance, "invalid governance");
    }

    function test_setGovernance_invalid_same_governance(address _newGovernance) external {
        vm.assume(_newGovernance != proxy.governance());
        vm.assume(_newGovernance != address(0x0));

        hoax(proxy.governance());
        proxy.setGovernance(_newGovernance);
        assertEq(proxy.governance(), _newGovernance, "invalid governance");

        hoax(proxy.governance());
        vm.expectRevert("already set");
        proxy.setGovernance(_newGovernance);

        assertEq(proxy.governance(), _newGovernance, "invalid governance");
    }

    function test_setGovernance_invalid_governance(address _governance, address _newGovernance) external {
        vm.assume(_newGovernance != address(0x0));
        vm.assume(_governance != proxy.governance());
        address governance = proxy.governance();

        hoax(_governance);
        vm.expectRevert("!governance");
        proxy.setGovernance(_newGovernance);

        assertEq(proxy.governance(), governance, "invalid governance");
    }

    function test_setGovernance_invalid_zero_address() external {
        address _newGovernance = address(0x0);

        hoax(proxy.governance());
        vm.expectRevert("!zeroaddress");
        proxy.setGovernance(_newGovernance);

        assertNotEq(proxy.governance(), _newGovernance, "invalid governance");
    }

    function test_approveExtraTokenRecipient_successful(address _token, address _recipient) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);

        hoax(governance);
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), _recipient, "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_token_not_safe(address _token, address _recipient) external {
        vm.assume(_token != address(0x0));
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!safeToken");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_token_zero(address _recipient) external {
        address _token = address(0x0);
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("!safeToken");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_recipient_zero(address _token) external {
        vm.assume(_token != address(0x0));
        address _recipient = address(0x0);
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);

        hoax(governance);
        vm.expectRevert("disallow zero");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_token_is_lock_token(address _recipient) external {
        address _token = proxy.LOCK_TOKEN();
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);

        hoax(governance);
        vm.expectRevert("!safeToken");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_token_is_reward_token(address _recipient) external {
        address _token = proxy.REWARD_TOKEN();
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);

        hoax(governance);
        vm.expectRevert("!safeToken");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_sender(
        address _sender,
        address _token,
        address _recipient
    ) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_recipient != address(0x0));
        vm.assume(_sender != address(0x0));
        vm.assume(_sender != proxy.governance());

        MockTokensValidator(tokensValidator).setValidToken(_token, true);

        hoax(_sender);
        vm.expectRevert("!governance");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_approveExtraTokenRecipient_invalid_already_approve(address _token, address _recipient) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);
        hoax(governance);
        proxy.approveExtraTokenRecipient(_token, _recipient);

        hoax(governance);
        vm.expectRevert("already approved");
        proxy.approveExtraTokenRecipient(_token, _recipient);

        assertEq(proxy.extraTokenRecipient(_token), _recipient, "invalid token recipient");
    }

    function test_revokeExtraTokenRecipient_successful(address _token, address _recipient) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        MockTokensValidator(tokensValidator).setValidToken(_token, true);
        hoax(governance);
        proxy.approveExtraTokenRecipient(_token, _recipient);

        hoax(governance);
        proxy.revokeExtraTokenRecipient(_token);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_revokeExtraTokenRecipient_invalid_not_approved(address _token, address _recipient) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("already revoked");
        proxy.revokeExtraTokenRecipient(_token);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_revokeExtraTokenRecipient_invalid_zero_token() external {
        address _token = address(0x0);
        address governance = proxy.governance();

        hoax(governance);
        vm.expectRevert("already revoked");
        proxy.revokeExtraTokenRecipient(_token);

        assertEq(proxy.extraTokenRecipient(_token), address(0x0), "invalid token recipient");
    }

    function test_revokeExtraTokenRecipient_invalid_sender(
        address _sender,
        address _token,
        address _recipient
    ) external {
        vm.assume(_token != address(0x0));
        vm.assume(_token != proxy.LOCK_TOKEN() && _token != proxy.REWARD_TOKEN());
        vm.assume(_sender != address(0x0));
        vm.assume(_sender != proxy.governance());
        vm.assume(_recipient != address(0x0));

        MockTokensValidator(tokensValidator).setValidToken(_token, true);
        hoax(proxy.governance());
        proxy.approveExtraTokenRecipient(_token, _recipient);

        hoax(_sender);
        vm.expectRevert("!governance");
        proxy.revokeExtraTokenRecipient(_token);

        assertEq(proxy.extraTokenRecipient(_token), _recipient, "invalid token recipient");
    }

    function test_claimExtraToken_successful(address _recipient, uint256 _extraTokenBalance) external {
        vm.assume(_extraTokenBalance > 0);
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();
        MockToken _extraToken = new MockToken();

        deal(address(_extraToken), proxyVoter, _extraTokenBalance);
        assertEq(_extraToken.balanceOf(proxyVoter), _extraTokenBalance, "invalid proxy voter extra token balance");

        MockTokensValidator(tokensValidator).setValidToken(address(_extraToken), true);
        hoax(governance);
        proxy.approveExtraTokenRecipient(address(_extraToken), _recipient);

        MockProxyVoter(proxyVoter).setExecuteResponse(true, "");

        hoax(_recipient);
        proxy.claimExtraToken(address(_extraToken));

        // Since we don't use the proxy voter implementation, we cannot check the recipient extra token balance.
    }

    function test_claimExtraToken_successful_zero_balance(address _recipient) external {
        vm.assume(_recipient != address(0x0));
        address governance = proxy.governance();
        MockToken _extraToken = new MockToken();

        MockTokensValidator(tokensValidator).setValidToken(address(_extraToken), true);
        hoax(governance);
        proxy.approveExtraTokenRecipient(address(_extraToken), _recipient);

        MockProxyVoter(proxyVoter).setExecuteResponse(true, "");

        hoax(_recipient);
        proxy.claimExtraToken(address(_extraToken));

        // Since we don't use the proxy voter implementation, we cannot check the recipient extra token balance.
    }

    function test_claimExtraToken_invalid_recipient(address _recipient, uint256 _extraTokenBalance) external {
        vm.assume(_extraTokenBalance > 0);
        vm.assume(_recipient != address(0x0));
        MockToken _extraToken = new MockToken();

        deal(address(_extraToken), proxyVoter, _extraTokenBalance);
        assertEq(_extraToken.balanceOf(proxyVoter), _extraTokenBalance, "invalid proxy voter extra token balance");

        MockTokensValidator(tokensValidator).setValidToken(address(_extraToken), true);
        MockProxyVoter(proxyVoter).setExecuteResponse(true, "");

        hoax(_recipient);
        vm.expectRevert("!token_recipient");
        proxy.claimExtraToken(address(_extraToken));

        // Since we don't use the proxy voter implementation, we cannot check the recipient extra token balance.
    }

    function test_deposit_successful(address _strategy, uint256 _tokenBalance) external {
        vm.assume(_tokenBalance > 0);
        vm.assume(_strategy != address(0x0));
        MockToken _token = new MockToken();
        address _gauge = address(9999);
        address governance = proxy.governance();

        hoax(governance);
        proxy.approveStrategy(_gauge, _strategy);
        deal(address(_token), address(proxy), _tokenBalance);
        _expect_call_deposit_successful(proxy, _gauge, address(_token), _tokenBalance, 1);

        MockProxyVoter(proxyVoter).setExecuteResponse(true, "", 3);
        hoax(_strategy);
        proxy.deposit(_gauge, address(_token));

        assertEq(_token.balanceOf(proxy.VOTER()), _tokenBalance, "invalid voter token balance");
    }

    function test_deposit_invalid_amount_zero(address _strategy) external {
        uint256 _tokenBalance = 0;
        vm.assume(_strategy != address(0x0));
        MockToken _token = new MockToken();
        address _gauge = address(9999);
        address governance = proxy.governance();

        hoax(governance);
        proxy.approveStrategy(_gauge, _strategy);
        deal(address(_token), address(proxy), _tokenBalance);
        _expect_call_deposit_successful(proxy, _gauge, address(_token), _tokenBalance, 0);

        hoax(_strategy);
        vm.expectRevert("!token_balance");
        proxy.deposit(_gauge, address(_token));

        assertEq(_token.balanceOf(proxy.VOTER()), _tokenBalance, "invalid voter token balance");
    }

    function test_deposit_invalid_sender(address _sender, address _strategy, uint256 _tokenBalance) external {
        vm.assume(_tokenBalance > 0);
        vm.assume(_strategy != address(0x0));
        vm.assume(_sender != address(0x0));
        vm.assume(_sender != _strategy);
        MockToken _token = new MockToken();
        address _gauge = address(9999);
        address governance = proxy.governance();

        hoax(governance);
        proxy.approveStrategy(_gauge, _strategy);
        deal(address(_token), address(proxy), _tokenBalance);
        _expect_call_deposit_successful(proxy, _gauge, address(_token), _tokenBalance, 0);

        hoax(_sender);
        vm.expectRevert("!strategy");
        proxy.deposit(_gauge, address(_token));

        assertEq(_token.balanceOf(proxy.VOTER()), 0, "invalid voter token balance");
        assertEq(_token.balanceOf(address(proxy)), _tokenBalance, "invalid proxy token balance");
    }

    function test_deposit_invalid_safe_execute(address _strategy, uint256 _tokenBalance) external {
        vm.assume(_tokenBalance > 0);
        vm.assume(_strategy != address(0x0));
        MockToken _token = new MockToken();
        address _gauge = address(9999);
        address governance = proxy.governance();

        hoax(governance);
        proxy.approveStrategy(_gauge, _strategy);
        deal(address(_token), address(proxy), _tokenBalance);

        MockProxyVoter(proxyVoter).setExecuteResponse(true, "", 1);
        hoax(_strategy);
        vm.expectRevert("!safe_execute");
        proxy.deposit(_gauge, address(_token));

        assertEq(_token.balanceOf(proxy.VOTER()), 0, "invalid voter token balance");
        assertEq(_token.balanceOf(address(proxy)), _tokenBalance, "invalid proxy token balance");
    }
}
