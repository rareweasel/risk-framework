// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";
import {IVault} from "../../src/interfaces/yearn/IVault.sol";
import {ERC20PresetFixedSupply} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {SuperToken} from "../../src/SuperToken.sol";
import {Strategy} from "../../src/StrategyStSuperYFI.sol";

// Base fixture deploying Vault
contract StrategyFixture is PRBTest, StdCheats {
    using SafeERC20 for IERC20;

    VyperDeployer private vyperDeployer = new VyperDeployer();
    ERC20PresetFixedSupply internal lockToken;
    SuperToken public superToken;
    IVault public vault;
    Strategy public strategy;
    IERC20 public weth;
    IERC20 public want;

    address public gov = address(0xBEEF);
    address public user = address(1);
    address public whale = address(2);
    address public rewards = address(3);
    address public guardian = address(4);
    address public management = address(5);
    address public strategist = address(6);
    address public keeper = address(7);
    address public voter = address(8);
    address public proxy = address(9); // TODO: remove and replace with mock contract

    uint256 public minFuzzAmt;
    // @dev maximum amount of want tokens deposited based on @maxDollarNotional
    uint256 public maxFuzzAmt;
    // @dev maximum dollar amount of tokens to be deposited
    uint256 public maxDollarNotional = 1_000_000;
    // @dev maximum dollar amount of tokens for single large amount
    uint256 public bigDollarNotional = 49_000_000;
    // @dev used for non-fuzz tests to test large amounts
    uint256 public bigAmount;
    // Used for integer approximation
    uint256 public constant DELTA = 10 ** 5;

    function setUp() public virtual {
        lockToken = new ERC20PresetFixedSupply("LockToken", "LT", 100000000000000000000000000, gov);
        superToken = new SuperToken("SuperToken", "ST", address(lockToken), voter, gov);

        want = IERC20(address(superToken));

        (address _vault, address _strategy) = deployVaultAndStrategy(
            address(want),
            gov,
            rewards,
            "",
            "",
            guardian,
            management,
            keeper,
            strategist
        );
        vault = IVault(_vault);
        strategy = Strategy(_strategy);

        minFuzzAmt = 10 ** vault.decimals() / 10;
        maxFuzzAmt = uint256(maxDollarNotional / 1) * 10 ** vault.decimals();
        bigAmount = uint256(bigDollarNotional / 1) * 10 ** vault.decimals();

        // add more labels to make your traces readable
        vm.label(address(vault), "Vault");
        vm.label(address(strategy), "Strategy");
        vm.label(address(want), "Want");
        vm.label(address(superToken), "SuperToken");
        vm.label(gov, "Gov");
        vm.label(user, "User");
        vm.label(whale, "Whale");
        vm.label(rewards, "Rewards");
        vm.label(guardian, "Guardian");
        vm.label(management, "Management");
        vm.label(strategist, "Strategist");
        vm.label(keeper, "Keeper");

        // do here additional setup
    }

    // Deploys a vault
    function deployVault(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management
    ) public returns (address) {
        vm.prank(_gov);
        IVault _vault = IVault(vyperDeployer.deployContract("src/", "Vault"));

        vm.prank(_gov);
        _vault.initialize(_token, _gov, _rewards, _name, _symbol, _guardian, _management);

        vm.prank(_gov);
        _vault.setDepositLimit(type(uint256).max);

        console.log("vault setup complete");

        return address(_vault);
    }

    // Deploys a strategy
    function deployStrategy(address _vault) public returns (address) {
        Strategy _strategy = new Strategy(_vault, proxy);

        return address(_strategy);
    }

    // Deploys a vault and strategy attached to vault
    function deployVaultAndStrategy(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management,
        address _keeper,
        address _strategist
    ) public returns (address _vaultAddr, address _strategyAddr) {
        _vaultAddr = deployVault(_token, _gov, _rewards, _name, _symbol, _guardian, _management);
        IVault _vault = IVault(_vaultAddr);

        vm.prank(_strategist);
        _strategyAddr = deployStrategy(_vaultAddr);
        Strategy _strategy = Strategy(_strategyAddr);

        vm.prank(_strategist);
        _strategy.setKeeper(_keeper);

        vm.prank(_gov);
        _vault.addStrategy(_strategyAddr, 10_000, 0, type(uint256).max, 1_000);

        return (address(_vault), address(_strategy));
    }
}
