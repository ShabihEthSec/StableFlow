// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library SafeCast {
    function toUint256(int128 x) internal pure returns (uint256) {
        require(x >= 0, "x < 0");
        return uint256(uint128(x));
    }

    function toInt256(uint128 x) internal pure returns (int256) {
        return int256(uint256(x));
    }

    function toInt256(int128 x) internal pure returns (int256) {
        require(x >= 0, "x < 0");
        return int256(x);
    }
}