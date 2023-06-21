// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

interface IStrategy {

    function asset() external view returns (address _asset);
    function vault() external view returns (address _vault);
    
    function balanceOf(address owner) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);

    function totalAssets() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
}
