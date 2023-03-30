// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INftStore {
    error InsufficientBalance();
    error UnAuthorized();
    error TokenIdAlreadyExist();
    error SignatureNotValid();

    event RedeemVoucher(address claimer, NFTVoucher nft, uint256 timestamp);
    event PaymentWithdrawn(address signer, uint256 amount, uint256 timestamp);
    event GovernanceUpdated(
        address oldAdmin,
        address newAdmin,
        uint256 timestamp
    );

    struct NFTVoucher {
        uint256 tokenId;
        uint256 price;
        string metadataUri;
    }

    /// @notice use for redeem voucher
    /// @param claimer The user address who wants to redeem voucher
    /// @param data NFTVoucher struct which contains details of NFT voucher
    /// @param signature signature of NFT creator
    function reedemVoucher(
        address claimer,
        NFTVoucher memory data,
        bytes calldata signature
    ) external payable;

    /// @notice use for withdraw Eth amount
    /// @notice withdraw payments can do by NFT Creator (signer in our case)
    function withdrawPayments() external;

    function transferGovernance(address _signer) external;

    /// @notice use to read contract states
    function getContractStates()
        external
        view
        returns (address, uint256, uint256);
}
