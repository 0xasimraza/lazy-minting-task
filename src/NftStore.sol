// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./INftStore.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NftStore is ERC721URIStorage, EIP712, INftStore {
    using ECDSA for bytes32;

    address public immutable signer;

    uint256 vouchersDistributed;
    uint256 ethTobeWithdraw;

    constructor(
        address _signer
    ) ERC721("NFT Store", "NFT") EIP712("NFT Store", "1") {
        signer = _signer;
    }

    function reedemVoucher(
        address _claimer,
        NFTVoucher memory message,
        bytes calldata signature
    ) external payable override {
        if (_exists(message.tokenId)) {
            revert TokenIdAlreadyExist();
        }

        if (msg.value < message.price) {
            revert InsufficientBalance();
        }

        _recSig(message, signature);

        ethTobeWithdraw += msg.value;

        _mint(_claimer, message.tokenId);
        _setTokenURI(message.tokenId, message.metadataUri);

        unchecked {
            vouchersDistributed++;
        }

        emit RedeemVoucher(_claimer, message, block.timestamp);
    }

    function withdrawPayments() external override {
        if (msg.sender != signer) {
            revert UnAuthorized();
        }

        if (ethTobeWithdraw <= 0) {
            revert InsufficientBalance();
        }

        uint256 pendingAmount = ethTobeWithdraw;

        ethTobeWithdraw = 0;

        payable(msg.sender).transfer(pendingAmount);

        emit PaymentWithdrawn(signer, pendingAmount, block.timestamp);
    }

    function getContractStates()
        external
        view
        override
        returns (address, uint256, uint256)
    {
        return (signer, vouchersDistributed, ethTobeWithdraw);
    }

    function _recSig(
        NFTVoucher memory message,
        bytes calldata signature
    ) internal view {
        bytes32 signedMessageHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();

        if (signedMessageHash.recover(signature) != signer) {
            revert SignatureNotValid();
        }
    }
}
