# (Expirmental) A Non-Dilutive 721 Utilizing Mimetic Metadata (On-Chain Metadata w/ Off-Chain Image Rendering)

> Note: This code is unaudited and absolutely not copy-paste ready. This project was the obessions of a mad man that needed a half-way step between where I was and where I was trying to get. In this implementation I've snipped many things from all around places to reach a conceptual state of the processing. Again, this is not a reference for how to do things, solely a reference of how the next stage came to be.

## Introduction

If you are not familiar with what Mimetic Metadata, it is an ERC721 extension that introduces the idea of generations to the capabilities of NFTs. With full holder control and project attachability.

The on-chain trait implementation is as follows:

1. Load Generation (Includes dynamic probabilistic weightings // definitely not fully functional) 
2. Load Trait Types (Inspired by many greats before me) 
3. Enable Generation 
4. Holders can focus Generation  

Now when we retrieve the token uri we would have retrieved on-chain metadata and we will have a ipfsHash with an appended dna that needs to render the visual assets. For the art, the system essentially operates like Art Blocks minus the fact that we have the attributes on chain.

Now, there is one major error in this implementation in that even if the metadata was on chain, retrieving and using that value on-chain would be beyond expensive. Simply too expensive. Conceptually, this is just another way to implement the concept of Mimetic Metadata because of course, no one shoe will ever fit all feet.

So, with this, we have the full implemented ability to have on-chain metadata traits while we render the image off-chain. For the renderer, you would just use your favorite assembler depending on the format that you are building in. Again situational and that is why there is nothing beyond the template provided in this repository.

For the contracts we've done a few things so let's go over that real quick.

During the progression of the original off-chain focused implementation I realized that although it is a better solution there are a lot of improvements still to be made. Namely, the manner in which things are calculated, represented and stored. The model doesn't need to fundamentally change we just need a stronger foundation if we have any exceptation of the industry adopting this new way of thinking. Thus, we are here today.

With that realization the contracts have now reached a 1/2 state where there are psuedo-modules as they merely operate in that manner conceptualy. In reality, they are just well handled pieces of data there is no module or external attachment or "utility extendability" and that is what we are really want, right?

Now we have `NonDilutive.sol` which is our NFT contract and then we have all the `Mimetic` prepended contracts that are the actual Mimetic Metadata implementation.

As it stands the method of retrieving a trait is using cumulative property weights which is an entirely new concept to me. That said, I do think it's the solution I was looking for and a "concept-allowing" test passed -- that is the extent of this repository. Pure education and exploration not in aim of perfection.

Because this contract is so abstracted and so poorly documented I recommend heading over to the test file and starting there.

If you run the tests you will immediately get a clear picture and you will be off to the races.

## Running The Project

Running the tests for the project is very simple. Combined with the in-contract documentation you should have everything you need to get rolling. Finally, you too can create a truly non-dilutive NFT collection.

Copy example.env to .env and enter values.
Use shell commands below:

```
npm i
npx hardhat test
```


