// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IOracle {

    event TokenAliasAdded(address tokenAddress, address tokenAliasAddress);
    event TokenAliasRemoved(address tokenAddress);

    function calculations() external view returns (address[] memory);

    function addTokenAlias(address tokenAddress, address tokenAliasAddress) external;

    function removeTokenAlias(address tokenAddress) external;

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}
