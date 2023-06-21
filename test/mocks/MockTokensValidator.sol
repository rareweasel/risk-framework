// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../../src/interfaces/ITokensValidator.sol";

contract MockTokensValidator is ITokensValidator {
    mapping(address => bool) internal _isValidToken;

    function isValidToken(address _token) external view returns (bool) {
        return _isValidToken[_token];
    }

    function setValidToken(address _token, bool _valid) external {
        _isValidToken[_token] = _valid;
    }
}
