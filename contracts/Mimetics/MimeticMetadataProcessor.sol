// SPDX-License-Indentifier: MIT
 
pragma solidity ^0.8.7;

import { IMimeticMetadataProcessor } from "./IMimeticMetadataProcessor.sol";

contract MimeticMetadataProcessor is 
    IMimeticMetadataProcessor 
{
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Hello friend, if you're reading this you may notice that your cpws are
     *     dynamic. This means you can realistically push the bounds of gas. However,
     *     doing so should not be done with the base. I love being a dev-maxi just
     *     as much as the next person, but this codebase is beyond experimental.
     *     Personal recommendation of 8 layer depth.
     */

    /**
     * @notice Generates a pseudo-random number with parameters that is hard for one entity to
     *        reasonably control.
     * @param _tokenId The token random number is being retrieved for
     * @return A pseudo-random uint256.
     */

    // TODO: Implement offset
    function getRandomNumber(uint256 _tokenId) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _tokenId
                )
            )
        );
    }

    /**
     * @dev This function selects a trait from the cpw utilizing the baseline seed that has been 
     *      provided through the Mimetic implementation.
     * @notice Readability was sacrificed in search of the most efficient trait selection.
     */
    function  getRandomTrait(
             uint256 _cpw
            ,uint256 _seed
        ) 
            internal 
            pure 
            returns (
                uint256
            ) 
        {
        // The smallest possible trait ID is 0.
        uint256 start;
        uint256 mid;
        // The largest possible trait ID is given by `(the last 8 bits) + 1` (see above).
        uint256 end = _cpw & 0xFF;
        // Bit shift the last 8 bits off after reading necessary information.
        _cpw >>= 8;
        // The seed is normalized to the total probability weighting. In other words,
        // `_cpw >> (end << 3)` evaluates to the first 8 bits of `_cpw`.
        _seed %= (_cpw >> (end << 3));

        uint256 selectedId;
        unchecked {
            // Binary search.
            while (start <= end) {
                mid = (start + end) >> 1;
                if ((_cpw >> (mid << 3)) & 0xFF <= _seed) start = mid + 1;
                else if (mid == 0) return end;
                else (selectedId, end) = (end, mid - 1);
            }
        }

        return selectedId;
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}