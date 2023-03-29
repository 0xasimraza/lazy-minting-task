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

    function testMintbySigner() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            tokenUri: "xyz/1"
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
            tokenUri: "xyz.com/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(other, message, signature);
        assertEq(t.ownerOf(message.tokenId), other, "Not the owner");
    }

    function testWithdrawAmountBySigner() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            tokenUri: "xyz/1"
        });

        bytes32 msgHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        t.reedemVoucher{value: 10 wei}(signer, message, signature);

        t.withdrawPayments();

        assertEq(address(signer).balance, 1 ether, "Not received");
        assertEq(address(t).balance, 0, "Amount remaining");
    }

    function testWithdrawAmountByAnyone() public {
        vm.startPrank(signer);
        vm.deal(signer, 1 ether);

        INftStore.NFTVoucher memory message = INftStore.NFTVoucher({
            tokenId: 0,
            price: 10,
            tokenUri: "xyz.com/1"
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
}
