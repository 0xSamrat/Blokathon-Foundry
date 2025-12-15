// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDustSweeper {
    event DustSwept(
        address indexed user,
        address[] tokens,
        uint256[] amounts,
        uint256 totalUsdtReceived
    );

    event UsdtWithdrawn(address indexed user, uint256 amount);

    event GardenDustSwept(
        address indexed owner,
        address[] tokens,
        uint256[] amounts,
        uint256 totalUsdtReceived
    );

    function sweepDust(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minUsdtOut
    ) external returns (uint256 totalUsdtReceived);

    function sweepGardenDust(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minUsdtOut
    ) external returns (uint256 totalUsdtReceived);

    function withdrawUsdt(uint256 amount) external;

    function getUsdtBalance(address user) external view returns (uint256);
}