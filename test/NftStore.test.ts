import { expect } from "chai";
import { ethers } from "hardhat";

describe("NftStore", function () {
  it("Should return nft store name", async function () {
    const NFTStore = await ethers.getContractFactory("NftStore");
    const nftStore = await NFTStore.deploy(
      "0xef045a554cbb0016275E90e3002f4D21c6f263e1"
    );
    await nftStore.deployed();
    expect(await nftStore.name()).to.equal("NFT Store");
  });
});
