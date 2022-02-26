// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IMimeticMetadataTrait } from "./IMimeticMetadataTrait.sol";

interface IMimeticMetadata is IMimeticMetadataTrait { 
    event GenerationChange(
         uint256 _layerId
        ,uint256 _tokenId
    );

    function setRevealed(
         uint256 _layerId
        ,uint256 _tokenId
    ) external;

    function getGenerationToken(
         uint256 _offset
        ,uint256 _tokenId
    ) 
        external 
        view 
        returns (
            uint256 generationTokenId
        );

    function loadGeneration(
         uint256 _layerId
        ,bool _enabled                  // evolution creator state
        ,bool _locked                   // evolution creator state
        ,bool _sticky                   // evolution holder state
        ,uint256 _cost                  // evolution availability
        ,uint256 _evolutionClosure      // evolution availability
        ,uint256[] calldata _cpws       // metadata
        ,string memory ipfsRendererHash
    )
        external;

    function toggleGeneration(
        uint256 _layerId
    ) external;
}