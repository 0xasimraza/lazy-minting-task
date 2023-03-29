// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./INftStore.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NftStore is ERC721URIStorage, EIP712, INftStore {
    using ECDSA for bytes32;

    address signer;

    uint256 tokenIds;
    uint256 public ethTobeWithdraw;

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
        if (msg.value < message.price) {
            revert InsufficientBalance();
        }
        _recSig(message, signature);

        _mint(_claimer, tokenIds);
        _setTokenURI(tokenIds, message.tokenUri);
        unchecked {
            tokenIds++;
        }
        ethTobeWithdraw += msg.value;
        emit RedeemVoucher(_claimer, message, block.timestamp);
    }

    function withdrawPayments() external override {
        if (ethTobeWithdraw <= 0) {
            revert InsufficientBalance();
        }
        if (msg.sender != signer) {
            revert UnAuthorized();
        }
        uint256 pendingAmount = ethTobeWithdraw;
        ethTobeWithdraw = 0;
        payable(msg.sender).transfer(pendingAmount);
        emit PaymentWithdrawn(signer, pendingAmount, block.timestamp);
    }

    function _recSig(
        NFTVoucher memory message,
        bytes calldata signature
    ) internal view {
        bytes32 signedMessageHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        require(
            signedMessageHash.recover(signature) == signer,
            "signature not valid"
        );
    }
}
