pragma solidity ^0.8.0;

contract RevertString {
    function reverse(string memory s) public pure returns (string memory) {
        bytes memory b = bytes(s);
        uint256 len = b.length / 2;
        for (uint256 i = 0; i < len; i++) {
            uint256 j = b.length - 1 - i;
            (b[i], b[j]) = (b[j], b[i]);
        }
        return string(b);
    }
}
