// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IMimeticMetadataTrait } from "./Modules/IMimeticMetadataTrait.sol";

interface IMimeticMetadataProcessor is IMimeticMetadataTrait { 
    struct Generation {
        /// @dev evolution states
        bool loaded;
        bool enabled;
        bool locked;
        bool sticky;
        uint256 cost;
        uint256 evolutionClosure;
        uint256 offset;
        uint256 top;
        /// @dev metadata
        uint256[] cpws;
        Trait[][8] traitTypes;
        string ipfsRendererHash;
    }
}