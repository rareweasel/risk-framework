// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library ScoresLib {

    function and(uint256 x, uint256 y) internal pure returns (uint256) {
        return x & y;
    }

    function or(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function xor(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function not(uint8 x) internal pure returns (uint256) {
        return ~x;
    }

    function shiftLeft(uint256 x, uint256 digits) internal pure returns (uint256) {
        return x << digits;
    }

    function shiftRight(uint256 x, uint256 digits) internal pure returns (uint256) {
        return x >> digits;
    }

    function mask(uint256 n) external pure returns (uint256) {
        /*
            Example, 
            10  > 01111111111
            3   > 0111
        */
        // 1 --> 1000 - 1 -> 0111
        return (1 << n) - 1;
    }

    function mask(uint256 total, uint256 start, uint256 offset) internal 
    pure returns 
        (
            uint256, // total mask
            uint256, // start mask
            uint256, // offset mask
            uint256 // packed mask
        ) {
        /*
            Example, 
            total  = 000000...0000000
            Test: 
            - 35, 15, 5
                11111 00000 00000
            - 35, 10, 5
                11111 00000
            - 35, 25, 5
                11111 00000 00000 00000 00000
            - 35, 30, 5
                11111 00000 00000 00000 00000 00000
            - 35, 5, 5
                011111
        */
        uint256 total0Mask = 0 << total;
        uint256 startMask = (1 << offset) - 1;
        uint256 offset0Mask = 0 << (start - offset);
        uint256 packed = startMask << (start - offset) | offset0Mask;
        return (total0Mask, startMask, offset0Mask, packed);
    }

    function lastNBits(uint256 x, uint256 n) internal pure returns (uint256) {
        /*
            Example, last 3 bits
            x           = 1101 = 13
            mask        = 0111
            x & mask    = 0101
        */
        // 1 --> 1000 - 1 -> 0111
        uint256 _mask = (1 << n) - 1;
        return x & _mask;
    }

    function lastNBitsUsingMod(uint256 x, uint256 n) internal pure returns (uint256) {
        return x % (1 << n);
    }

    function getNBits(uint256 value, uint256 x, uint256 start, uint256 offset) internal pure returns (uint256) {
        /*
            Example, 5-10 bits
            x           = 00000 00000 00000 00000
            mask        = 0111
            x & mask    = 0101
        */

        // 1 --> 1000 - 1 -> 0111

        // Test 5 4 3 2 1 2 3 -> 5506139203, 35, 15, 5

        // 01010 0100 00011 00010 00001 00010 00011
        //                              11111 00000
        //                                 10 00000
        // 1 00000 00000
        uint256 _mask;
        (,,,_mask) = mask(x, start, offset);
        return (value & _mask) >> (start - offset);
    }
}