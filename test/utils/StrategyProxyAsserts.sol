// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {console2 as console} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {IProxy} from "../../src/interfaces/yearn/IProxy.sol";
import {StrategyProxyBase} from "../../src/StrategyProxyBase.sol";

// Base fixture deploying Vault
contract StrategyProxyAsserts is PRBTest, StdCheats, StdUtils {
    
    function _expect_call_deposit_successful(
        StrategyProxyBase _proxy,
        address _gauge,
        address _token,
        uint256 _tokenBalance,
        uint64 _expectedCalls
    ) internal {
        vm.expectCall(
            _proxy.VOTER(),
            abi.encodeCall(
                IProxy(_proxy.VOTER()).execute,
                (_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, 0))
            ),
            _expectedCalls
        );
        if (_tokenBalance > 0) {
            // Since the amount is 0 in the previous expectCall, when _tokenBalance is 0, the vm call fails with the error below:
            // Reason: Counted expected calls can only bet set once.
            // So, we added the if _tokenBalance > 0 to avoid the error.
            vm.expectCall(
                _proxy.VOTER(),
                abi.encodeCall(
                    IProxy(_proxy.VOTER()).execute,
                    (_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, _tokenBalance))
                ),
                _expectedCalls
            );
        }
        vm.expectCall(
            _proxy.VOTER(),
            abi.encodeCall(
                IProxy(_proxy.VOTER()).execute,
                (_gauge, 0, abi.encodeWithSignature("deposit(uint256)", _tokenBalance))
            ),
            _expectedCalls
        );
    }
}
