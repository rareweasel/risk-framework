// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../src/interfaces/yearn/IProxy.sol";

contract MockProxyVoter is IProxy {
    struct ExecuteResponse {
        bool success;
        bytes returnData;
        uint256 totalExecution;
        uint256 currentExecution;
    }

    ExecuteResponse internal _executeResponse;

    function setExecuteResponse(bool success, bytes memory returnData) external {
        setExecuteResponse(success, returnData, 1);
    }

    function setExecuteResponse(bool success, bytes memory returnData, uint256 totalExecution) public {
        _executeResponse.success = success;
        _executeResponse.returnData = returnData;
        _executeResponse.totalExecution = totalExecution;
        _executeResponse.currentExecution = 1;
    }

    function execute(address, uint256, bytes calldata) external returns (bool, bytes memory) {
        bool success = _executeResponse.success;
        bytes memory returnData = _executeResponse.returnData;
        if (_executeResponse.currentExecution == _executeResponse.totalExecution) {
            _executeResponse.currentExecution = 1;
            _executeResponse.success = false;
            _executeResponse.returnData = "";
        } else {
            _executeResponse.currentExecution++;
        }
        return (success, returnData);
    }

    function increaseAmount(uint256) external {}

    function extendUnlockTime(uint256) external {}
}
