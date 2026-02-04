// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStableFlowVault {
    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
}
