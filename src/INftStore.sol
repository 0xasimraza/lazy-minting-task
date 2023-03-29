// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INftStore {
    error InsufficientBalance();
    error UnAuthorized();
    error TokenIdAlreadyExist();
    error SignatureNotValid();

    event RedeemVoucher(address claimer, NFTVoucher nft, uint256 timestamp);
    event PaymentWithdrawn(address signer, uint256 amount, uint256 timestamp);

    struct NFTVoucher {
        uint256 tokenId;
        uint256 price;
        string tokenUri;
    }

    function reedemVoucher(
        address claimer,
        NFTVoucher memory data,
        bytes calldata signature
    ) external payable;

    function withdrawPayments() external;
}
