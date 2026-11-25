// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomaToInt {

    // 只读输入、不访问 storage，因此使用 calldata 和 pure。
    function toInt(string calldata s) public pure returns (uint256) {
        bytes calldata arr = bytes(s);
        uint256 len = arr.length;
        require(len >= 1 && len <= 15, "s length is not in range");

        uint256 res;
        uint256 rightValue;
        // 从右往左：IV 先加 V 的 5，再减 I 的 1，不会执行 0 - 1。
        // 缓存右邻居的数值，每个符号只转换一次，额外空间为 O(1)。
        for (uint256 i = len; i > 0;) {
            // i > 0 已保证减一安全，不需要重复的下溢检查。
            unchecked {
                --i;
            }
            uint256 v = findIntVal(arr[i]);
            if (v < rightValue) {
                res -= v;
            } else {
                res += v;
            }
            rightValue = v;
        }
        // 这里只检查符号和长度，不验证 IIII、IL 等排列是否规范。
        return res;
    }

    function findIntVal(bytes1 c) public pure returns (uint256) {
        if (c == bytes1("I")) {
            return 1;
        } else if (c == bytes1("V")) {
            return 5;
        } else if (c == bytes1("X")) {
            return 10;
        } else if (c == bytes1("L")) {
            return 50;
        } else if (c == bytes1("C")) {
            return 100;
        } else if (c == bytes1("D")) {
            return 500;
        } else if (c == bytes1("M")) {
            return 1000;
        }
        revert("Invalid Roman symbol");
    }
}
