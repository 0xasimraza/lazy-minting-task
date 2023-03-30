// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/NftStore.sol";

import "../src/INftStore.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract NftStoreTest is Test {
    using ECDSA for bytes32;
    string[] private userLabels;
    // address payable internal user1;
    // address payable internal user2;
    address payable internal other;

    address signer;
    uint256 privateKey =
        0x1010101010101010101010101010101010101010101010101010101010101010;
    NftStore t;

    function setUp() public {
        userLabels = new string[](2);
        // userLabels.push("user1");
        // userLabels.push("user2");
        userLabels.push("other");

        signer = vm.addr(privateKey);
        other = payable(vm.addr(1));
        t = new NftStore(signer);
    }

    function testName() public {
        assertEq(t.name(), "NFT Store");
    }

    function testFuzzMintBySigner(
        uint256 _privateKey,
        uint256 _tokenId,
        uint256 _price
    ) public {
        vm.assume(_privateKey != 0);
        vm.assume(
            _privateKey <
                115792089237316195423570985008687907852837564279074904382605163141518161494337
        );
        vm.assume(_tokenId < type(uint256).max);
        vm.assume(_price < type(uint256).max);
        vm.assume(_price != 0);
        address _signer = vm.addr(_privateKey);
        NftStore _t = new NftStore(_signer);
        vm.assume(_signer != address(0));

        vm.startPrank(_signer);
        vm.deal(_signer, _price);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: _tokenId,
            price: _price,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        _t.reedemVoucher{value: _price}(_signer, message, signature);
        assertEq(_t.ownerOf(_tokenId), _signer, "Not the owner");
    }

    function testMintbySigner() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(signer, message, signature);
        assertEq(t.ownerOf(message.tokenId), signer, "Not the owner");
    }

    function testMintbyAnyone() public {
        vm.startPrank(other);
        vm.deal(other, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(other, message, signature);
        assertEq(t.ownerOf(message.tokenId), other, "Owner not matched");
    }

    function testReMintSameIdbyAnyone() public {
        vm.startPrank(other);
        vm.deal(other, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(other, message, signature);

        bytes4 selector = bytes4(keccak256("TokenIdAlreadyExist()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        t.reedemVoucher{value: 10 wei}(other, message, signature);
    }

    function testWithdrawAmountBySigner() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(signer, message, signature);

        t.withdrawPayments();

        assertEq(address(signer).balance, 1 ether, "Eth not received");
        assertEq(address(t).balance, 0, "Amount remaining in contract");
    }

    function testWithdrawAmountByAnyone() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(signer, message, signature);
        vm.stopPrank();
        vm.startPrank(other);

        bytes4 selector = bytes4(keccak256("UnAuthorized()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        t.withdrawPayments();
    }

    function testWithdrawZeroAmountBySigner() public {
        vm.startPrank(signer);

        bytes4 selector = bytes4(keccak256("InsufficientBalance()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        t.withdrawPayments();
    }

    function testMintNftWithInvalidSignature() public {
        vm.startPrank(other);
        vm.deal(other, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        bytes4 selector = bytes4(keccak256("SignatureNotValid()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        t.reedemVoucher{value: 10 wei}(
            other,
            INftStore.NFTVoucher({
                tokenId: 1,
                price: 10,
                metadataUri: "xyz.com/1"
            }),
            signature
        );
    }

    function testNftMintsbySignerAndAnyone() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message1 = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash1 = keccak256(abi.encode(message1))
            .toEthSignedMessageHash();
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, msgHash1);

        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        assertEq(signature1.length, 65);

        t.reedemVoucher{value: 10 wei}(signer, message1, signature1);
        assertEq(t.ownerOf(message1.tokenId), signer, "Owner not matched");
        vm.stopPrank();

        vm.startPrank(other);
        vm.deal(other, 1 ether);

        INftStore.NFTVoucher memory message2 = INftStore.NFTVoucher({
            tokenId: 1,
            price: 50,
            metadataUri: "xyz.com/2"
        });

        bytes32 msgHash2 = keccak256(abi.encode(message2))
            .toEthSignedMessageHash();
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(privateKey, msgHash2);

        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        assertEq(signature2.length, 65);

        t.reedemVoucher{value: 50 wei}(other, message2, signature2);
        assertEq(t.ownerOf(message2.tokenId), other, "Owner not matched");
    }

    function testContractCallStates() public {
        vm.startPrank(other);
        vm.deal(other, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            metadataUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(other, message, signature);
        (
            address _signer,
            uint256 _vouchersDistributed,
            uint256 _ethTobeWithdraw
        ) = t.getContractStates();

        console.log("_signer: ", _signer);
        console.log("_vouchersDistributed: ", _vouchersDistributed);
        console.log("_ethTobeWithdraw: ", _ethTobeWithdraw);
    }
}
