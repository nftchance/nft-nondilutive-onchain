//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IERC721  } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IMimeticMetadata } from "./Modules/IMimeticMetadata.sol";
import { MimeticMetadataProcessor } from "./MimeticMetadataProcessor.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

error GenerationNotReady();
error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();
error GenerationCostMismatch();
error GenerationDepthExceeded();

error TokenNotRevealed();
error TokenRevealed();

contract MimeticMetadata is 
     IMimeticMetadata
    ,Ownable
    ,MimeticMetadataProcessor
{ 
    using Strings for uint256;

    uint256 public maxSupply;

    mapping(uint256 => Generation) public generations;

    mapping(uint256 => uint256) tokenToGeneration;
    mapping(bytes32 => uint256) tokenGenerationToFunded;

    /**
     * @notice Allows the project owner to establish a new generation. Generations are enabled by 
     *      default. With this we initialize the generation to be loaded.
     * @dev _name is passed as a param, if this is not needed; remove it. Don't be superfluous.
     * @dev only accessed by owner of contract
     * @param _layerId the z-depth of the metadata being loaded
     * @param _enabled a generation can be connected before a token can utilize it
     * @param _locked can this layer be disabled by the project owner
     * @param _sticky can this layer be removed by the holder
     * @param _cost the focus cost
     * @param _evolutionClosure if set to zero, disabled. If not set to zero is the last timestamp
     *                          at which someone can focus this generation
     * @param _cpws the probabilistic weight 
     */
    function loadGeneration(
         uint256 _layerId
        ,bool _enabled                  // evolution creator state
        ,bool _locked                   // evolution creator state
        ,bool _sticky                   // evolution holder state
        ,uint256 _cost                  // evolution availability
        ,uint256 _evolutionClosure      // evolution availability
        ,uint256[] memory _cpws
        ,string memory _ipfsRendererHash
    )
        override 
        public 
        virtual 
        onlyOwner 
    {
        Generation storage generation = generations[_layerId];

        // Make sure that we are not overwriting an existing layer.
        if(generation.loaded) revert GenerationAlreadyLoaded();

        generation.loaded = true;
        
        /// @dev evolution states
        generation.enabled = _enabled;
        generation.locked = _locked;

        generation.sticky = _sticky;
        generation.cost = _cost;
        generation.evolutionClosure = _evolutionClosure;
        generation.offset = 0;
        generation.top = 0;

        /// @dev metadata
        generation.cpws = _cpws;
        generation.ipfsRendererHash = _ipfsRendererHash;
    }

    /**
    * @notice Used to load the front-end on-chain metadata for a token. This includes all visual 
    *         apperance aspects such as name, type, pixels and the pixel count. So essentially,
    *         this is where the core metadata is loaded however none of the odds/probabilities
    *         are calculated here this is merely a data dictionary that needs to be initialized.
    * @dev To pass an array of traits you just do [(,,,),(,,,),(,,,)] with the values filled in.
    * @dev A maximum of 8 trait types can exist per generation
    * @param _generationLayer the generation this trait is for
    * @param _traitTypeLayer which layer of rendering this type is found
    * @param _traits the list of traits being loaded into this attribute
     */
    function loadTraitType(
         uint256 _generationLayer
        ,uint256 _traitTypeLayer
        ,string calldata _traitTypeName
        ,string[] calldata _traits
    ) 
        public
        virtual
        onlyOwner
    {
        Generation storage generation = generations[_generationLayer];

        for(uint256 i; i < _traits.length; i++) { 
            generation.traitTypes[_traitTypeLayer].push(
                Trait(
                     _traits[i]         // trait name
                    ,_traitTypeName     // attribute name
                )
            );
        }
    }

    /**
     * @notice Used to toggle the state of a generation. Disable generations cannot be focused by 
     *         token holders.
     */
    function toggleGeneration(
        uint256 _layerId
    )
        override 
        public
        virtual
        onlyOwner 
    {
        Generation storage generation = generations[_layerId];

        // Make sure that the token isn't locked (immutable but overlapping keywords is spicy)
        if(generation.enabled && generation.locked) revert GenerationNotToggleable();

        generations[_layerId].enabled = !generation.enabled;
    }

    /**
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function _getTokenGeneration(
        uint256 _tokenId
    )
        internal
        virtual
        view
        returns(
            uint256
        )
    {
        return tokenToGeneration[_tokenId];       
    }

    /**
     * @notice Generates a psuedo-random number that is to be used for the 
     *         metadata offset. In production, this realistically should be an
     *         implementation with VRF (Chainlink). It is incredibly easy to setup
     *         and use, additionally with this structure there is no reason it needs 
     *         to be expensive.
     * @dev A focus of psuedo-random number quality has not been a focus. In order for
     *         for the modulus to even return a fair chance for all #s it must be a 
     *         power of 2.
     * @param _layerId the generation the offset is used for.
     */
    function _getOffset(
        uint256 _layerId
    ) 
        internal 
        view 
        returns (
            uint256
        ) 
    {
        return uint256(
            keccak256(
                abi.encodePacked(
                     msg.sender
                    ,_layerId
                    ,block.number
                    ,block.difficulty
                )
            )
        ) % maxSupply + 1;
    }

    /**
     * @notice Allows for generation-level reveal. That means that just because the assets
     *         in Generation Zero have been revealed, Generation One is not revealed. The
     *         reveal mechanisms of them are entirely separate. Precisely like a normal
     *         ERC721 token.
     * @notice Cannot be reverted once a token has been revealed. No mutable metadata!
     * @dev With this implementation it is vital that you implement and utilize an offset.
     *         This is not something that you can skip because you don't want to work
     *         with Chainlink or another VRF method. Even if not VRF, you must implement
     *         at least a generally fair offset mechanism. Holders for the most part
     *         do not know how Solidity works. That does not mean you take advantage of that.
     * @param _layerId the generation that is being revealed
     * @param _topTokenId the highest token id to be revealed
     */
    function setRevealed(
         uint256 _layerId
        ,uint256 _topTokenId
    )
        override
        public
        virtual
        onlyOwner
    {
        Generation storage generation = generations[_layerId];

        // Make sure the generation has been loaded and enabled
        if(!generation.loaded || !generation.enabled) revert GenerationNotEnabled();

        // Make sure that the amount of tokens revealed is not being lowered
        if(_topTokenId < generation.top) revert TokenRevealed();

        // Make sure that we create the offset the first time a generation is revealed
        if(generation.offset == 0) {
            generation.offset = _getOffset(_layerId);
        } 

        // Finally set the top token of the generation
        generation.top = _topTokenId;
    }

    /**
     * @notice Function that controls which metadata the token is currently utilizing.
     *         By default every token is using layer zero which is loaded during the time
     *         of contract deployment. Cannot be removed, is immutable, holders can always
     *         revert back. However, if at any time they choose to "wrap" their token then
     *         it is automatically reflected here.
     * @notice Errors out if the token has not yet been revealed within this collection.
     * @param _tokenId the token we are getting the URI for
     * @return _tokenURI The internet accessible URI of the token 
     */
    function _tokenURI(
        uint256 _tokenId
    ) 
        internal
        virtual 
        view 
        returns (
            string memory
        ) 
    {
        uint256 tokenGeneration = tokenToGeneration[_tokenId];

        // Make sure that the token has been revealed
        Generation storage generation = generations[tokenGeneration];

        // if not revealed utilize placeholder initialized data
        if(_tokenId > generation.top) return "";

        string memory metadataString = string(
            abi.encodePacked(
                 '{"trait_value":"Generation","value": "'
                ,tokenGeneration.toString()
                ,'"},'
            )
        );

        uint256 seed = getRandomNumber(
             tokenGeneration
            ,_tokenId
        );

        // Assemble the metadata of the token
        for(uint256 z; z < generation.cpws.length; z++) { 
            // Retrieve the trait
            uint256 shift = z * 8;

            uint256 traitIndex = getRandomTrait(
                  generation.cpws[z]
                 ,seed >> shift
            );
            
            Trait storage trait = generation.traitTypes[z][traitIndex]; 

            // Build the object data for the trait
            metadataString = string(
                abi.encodePacked(
                    metadataString
                    ,string(
                        abi.encodePacked(
                            '{"trait_type":"'
                            ,trait.traitType
                            ,'","value":"'
                            ,trait.traitName
                            ,'"}'
                        )
                    )
                )
            );

            // Make sure we have our trailing commas when needed
            if(z != generation.cpws.length - 1) {
                metadataString = string(
                    abi.encodePacked(
                        metadataString
                        ,string(
                            abi.encodePacked(
                                ","
                            )
                        )
                    )
                );
            }
        }

        // Build finalized token metadata
        string memory attributesString = string(
            abi.encodePacked(
                "["
                ,metadataString
                ,"]"
            )
        );

        // Append and return the collection data while wrapping it as JSON
        return string(
            abi.encodePacked(
                 "data:application/json;base64,"
                ,encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Mimetic Metadata #'
                                ,_tokenId.toString()
                                ,'", "description": "Mimetic Metadata enables the on-chain evolution of NFT tokens. The Generation '
                                ,tokenGeneration.toString()
                                ,' DNA of your character is: '
                                ,seed.toString()
                                ,'","image":"ipfs://'
                                ,generation.ipfsRendererHash
                                ,'/?dna='
                                ,seed.toString()
                                ,'", "attributes":'
                                ,attributesString
                                ,'}'
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     *  @notice Internal view function to clean up focusGeneration(). Pretty useless but the
     *          function was getting out of control.
     */
    function _generationEnabled(Generation storage generation) 
        internal 
        view 
        returns (
            bool
        ) 
    {
        if(!generation.enabled) return false;
        if(generation.evolutionClosure != 0) return block.timestamp < generation.evolutionClosure;
        return true;
    }

    /**
     * @notice Function that allows token holders to focus a generation and wear their skin.
     *         This is not in control of the project maintainers once the layer has been 
     *         initialized.
     * @dev This function is utilized when building supporting functions around the concept of 
     *         extendable metadata. For example, if Doodles were to drop their spaceships, it would 
     *         be loaded and then enabled by the holder through this function on a front-end.
     * @param _layerId the layer that this generation belongs on. The bottom is zero.
     * @param _tokenId the token that we are updating the metadata for
     */
    function _focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    )
        internal
        virtual
    {
        // TODO: Add the ability to limit focus of a generation if you have evolved to a whitelisted generation
            // Should probably check if they've funded it yet

        uint256 activeGenerationLayer = tokenToGeneration[_tokenId]; 
        if(activeGenerationLayer == _layerId) revert GenerationNotDifferent();
        
        // Make sure that the generation has been enabled
        Generation storage generation = generations[_layerId];
        if(!_generationEnabled(generation)) revert GenerationNotEnabled();

        // Make sure a user can't take off a sticky generation
        if(generations[activeGenerationLayer].sticky && _layerId < activeGenerationLayer) revert GenerationNotDowngradable(); 

        // Make sure they've supplied the right amount of money to unlock access
        bytes32 tokenIdGeneration = keccak256(abi.encodePacked(_tokenId, _layerId));
        if(msg.value + tokenGenerationToFunded[tokenIdGeneration] != generation.cost) revert GenerationCostMismatch();
        tokenGenerationToFunded[tokenIdGeneration] = msg.value;

        // Finally evolve to the generation
        tokenToGeneration[_tokenId] = _layerId;

        emit GenerationChange(
             _layerId
            ,_tokenId
        );
    }
}