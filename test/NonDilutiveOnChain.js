const { assert } = require('chai')
const { ethers } = require("hardhat");

const chai = require('chai')
    .use(require('chai-as-promised'))
    .should()

var cpws;
var traits;

describe("Non-Dilutive Token", () => {
    before(async () => {
        [
            owner,
            address1,
            address2
        ] = await ethers.getSigners();

        priceInWei = "20000000000000000"

        // base testing values
        cpws = [
            "0xFFDEBD9D7E60402007",
            "0x00FDF5EBE9D9D8D1C5B8B4A7938E8A68584E2B1F12",
            "0xFDF4E8E0DBD4D0CCC9C6C4C2BBB2AEABA19793897F77726B5B58524C4A463E1E",
            "0xFFFAF5EBE6DEDAD2CFC3BBB6AFAAA8A399918D877F787569686158534B45431E",
            "0xFFF7F1E3DAC7C1B3AAA8A29E948C897F736135341E170C16",
            "0xFFF8F4EBE5DFD8D0CDCBC9B6A8A2A19E9D9B9A8E8B89605F5B59575643403D1E",
            "0xFFEAD4C9BDB7B306",
        ]

        Contract = await ethers.getContractFactory("NonDilutive");
        contract = await Contract.deploy(
            "Non-Dilutive",             // name
            "No-D",                     // symbol
            900,                        // max supply
            cpws,                       // base layer weights
            "generation-0"              // ipfs renderer hash
        );

        contract = await contract.deployed();
    })

    it('Contract deploys successfully.', async() => {
        address = contract.address
        assert.notEqual(address, '')
        assert.notEqual(address, 0x0)
        assert.notEqual(address, null)
        assert.notEqual(address, undefined)
    });

    it('Contract has a name.', async() => {
        let name = await contract.name()
        assert.equal(name, 'Non-Dilutive')
    });

    it('Contract has the right price.', async() => {
        price = await contract.COST();
        assert.equal(price.toString(), priceInWei)
    });

    // Load trait types
    it('load trait types', async () => { 
        // load in the trait dictionaries

        // max amount of traits in a type is 31
        traits = [
            ['1', '2', '3', '4', '5', '6', '7', '8'],
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19'],
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'],
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'],
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'],
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'],
            ['1', '2', '3', '4', '5', '6', '7']
        ]

        await contract.loadTraitType(0, 0, 'trait_one', traits[0]);
        await contract.loadTraitType(0, 1, 'trait_two', traits[1]);
        await contract.loadTraitType(0, 2, 'trait_three', traits[2]);
        await contract.loadTraitType(0, 3, 'trait_four', traits[3]);
        await contract.loadTraitType(0, 4, 'trait_five', traits[4]);
        await contract.loadTraitType(0, 5, 'trait_six', traits[5]);
        await contract.loadTraitType(0, 6, 'trait_seven', traits[6]);
    })

    it('Minting 1 in public sale should fail before enabling generation 0.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(1, { value: ethers.utils.parseEther("0.02") }).should.be.revertedWith('MintNotEnabled')

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "1")
    });

    it("Toggle generation 0", async () => { 
        await contract.toggleGeneration(0);
     });
     

    it('Minting 1 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(1, { value: ethers.utils.parseEther("0.02") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "2")
    });

    it('Minting 2 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(2, { value: ethers.utils.parseEther("0.04") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "4")
    });

    it('Minting 10 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(10, { value: ethers.utils.parseEther("0.2") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "14")
    });

    // token uri is currently empty when not revealed
    it('Validate token uri', async () => { 
        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri, "");
    });

    it('Reveal generation zero', async () => { 
        await contract.setRevealed(0, 500);
        await contract.setRevealed(0, 200).should.be.revertedWith('TokenRevealed');
    });

    it('Validate token uri after having revealed', async () => { 
        // get the base token id of this genreation
        tokenUri = await contract.tokenURI(1);
        console.log('tokenUri: ', tokenUri);
        assert.equal(tokenUri.includes(`data:application`), true);
    });

    it('Get token generation', async () => {
        generation = await contract.getTokenGeneration(1);
        assert.equal(generation.toString(), "0");
    });

    it('Getting token generation fails for tokens not minted', async () => { 
        generation = await contract.getTokenGeneration(100).should.be.rejectedWith('TokenNonExistent')
    });

    it('Reconnecting layer zero fails', async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(0, 1).should.be.revertedWith("GenerationNotDifferent")
    });

    it("Connect generation 1", async () => {
        await contract.loadGeneration(
            1,
            false,
            true,
            false,
            0,
            0,
            cpws,
            "generation-1"
        )

        await contract.loadTraitType(1, 0, 'trait_one', traits[0]);
        await contract.loadTraitType(1, 1, 'trait_two', traits[1]);
        await contract.loadTraitType(1, 2, 'trait_three', traits[2]);
        await contract.loadTraitType(1, 3, 'trait_four', traits[3]);
        await contract.loadTraitType(1, 4, 'trait_five', traits[4]);
        await contract.loadTraitType(1, 5, 'trait_six', traits[5]);
        await contract.loadTraitType(1, 6, 'trait_seven', traits[6]);
    });

    it("Connect reconnect generation 1", async () => { 
        await contract.loadGeneration(
            1,
            false,
            true,
            false,
            0,
            0,
            cpws,
            "generation-1"
        ).should.be.revertedWith('GenerationAlreadyLoaded')
    });

    it("Cannot focus generation 1 while disabled", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1).should.be.revertedWith("GenerationNotEnabled")
    });

    it("Enable generation 1", async () => { 
       await contract.toggleGeneration(1);
    });

    it("Disable generation 1 should fail", async () => { 
        await contract.toggleGeneration(1).should.be.revertedWith('GenerationNotToggleable');
    });

    it("Can now focus generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1)
    });


    it('Validate token uri is unrevealed after generation 1 upgrade', async () => { 
        tokenUri = await contract.tokenURI(1);
        console.log('tokenUri: ', tokenUri);
        assert.equal(tokenUri, "");
    });

    it("Can focus generation 0 after upgrading to generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(0, 1)

        console.log('tokenUri :', tokenUri);
        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`data:application`), true);
    });

    it('Reveal generation 1 assets', async () => { 
        await contract.setRevealed(1, 500);
    });

    it("Can reenable generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1)

        tokenUri = await contract.tokenURI(1);
        console.log('tokenUri :', tokenUri);
        assert.equal(tokenUri.includes(`data:application`), true);
    })

    it("Load generation 2", async () => { 
        await contract.loadGeneration(
            2,
            true,
            true,
            true,
            '20000000000000000',
            0,
            cpws,
            'generation-2'
        )

        await contract.loadTraitType(2, 0, 'trait_one', traits[0]);
        await contract.loadTraitType(2, 1, 'trait_two', traits[1]);
        await contract.loadTraitType(2, 2, 'trait_three', traits[2]);
        await contract.loadTraitType(2, 3, 'trait_four', traits[3]);
        await contract.loadTraitType(2, 4, 'trait_five', traits[4]);
        await contract.loadTraitType(2, 5, 'trait_six', traits[5]);
        await contract.loadTraitType(2, 6, 'trait_seven', traits[6]);

        await contract.setRevealed(2, 500);
    });

    it("Focus generation 2 while paying", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(2, 1, { value: ethers.utils.parseEther("0.02")});

        tokenUri = await contract.tokenURI(1);
        console.log('tokenUri :', tokenUri);
        assert.equal(tokenUri.includes(`data:application`), true);
    });

    it("Cannot downgrade from generation 2", async () => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1).should.be.revertedWith('GenerationNotDowngradable')
    });

    it("Project owner cannot disable generation 2", async () => { 
        await contract.toggleGeneration(2).should.be.revertedWith('GenerationNotToggleable');
    });
})