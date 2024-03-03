// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Merkle} from "murky/Merkle.sol";
import {NFT} from "../src/NFT.sol";

contract NFTDiscountTest is Test {
    NFT public nft;
    Merkle m;

    address owner = address(1);
    address discounter1 = address(0xd15c);

    bytes32[] discountData;
    bytes32 discountRoot;
    uint256 discountTreeSize = 10;

    uint256 priceWithDiscount;

    event DiscountClaimed(uint256 index, address account);

    function setUp() public {
        m = new Merkle();

        discountData = getDiscountData();
        discountRoot = m.getRoot(discountData);
        nft = new NFT("NFT", "NFT", owner, discountRoot);

        priceWithDiscount = nft.PRICE_WITH_DISCOUNT();
    }

    function test_Root() public {
        assertNotEq(discountRoot, bytes32(0));
        assertEq(nft.DISCOUNT_TREE_ROOT(), discountRoot);
    }

    function test_MintOneWithDiscount() public {
        bytes32[] memory proof = m.getProof(discountData, 0);

        vm.prank(discounter1);
        vm.deal(discounter1, priceWithDiscount);
        nft.mintWithDiscount{value: priceWithDiscount}(proof, 0);

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), discounter1);
    }

    function test_MintWithInvalidPrice() public {
        bytes32[] memory proof = m.getProof(discountData, 0);
        uint256 price = priceWithDiscount - 1;

        vm.prank(discounter1);
        vm.deal(discounter1, price);
        vm.expectRevert(abi.encodeWithSelector(NFT.NFTPriceNotMatched.selector, priceWithDiscount, price));
        nft.mintWithDiscount{value: price}(proof, 0);
    }

    function test_MintTwiceWithDiscount() public {
        bytes32[] memory proof = m.getProof(discountData, 0);

        vm.prank(discounter1);
        vm.deal(discounter1, priceWithDiscount);
        nft.mintWithDiscount{value: priceWithDiscount}(proof, 0);

        vm.expectRevert(abi.encodeWithSelector(NFT.NFTAlreadyClaimed.selector, 0));
        nft.mintWithDiscount{value: priceWithDiscount}(proof, 0);
    }

    function test_MintAllDiscountedNFTs() public {
        assertEq(nft.totalSupply(), 0);

        for (uint160 i = 0; i < uint160(discountTreeSize); i++) {
            bytes32[] memory proof = m.getProof(discountData, i);

            address discounter = getDiscounterAddress(i);
            vm.prank(discounter);
            vm.deal(discounter, priceWithDiscount);
            nft.mintWithDiscount{value: priceWithDiscount}(proof, i);

            assertEq(nft.ownerOf(i), discounter);
        }

        assertEq(nft.totalSupply(), discountTreeSize);
    }

    function test_MintWithDiscountByStranger() public {
        bytes32[] memory proof = m.getProof(discountData, 0);

        vm.prank(address(0xdead));
        vm.deal(address(0xdead), priceWithDiscount);

        vm.expectRevert(abi.encodeWithSelector(NFT.NFTDiscountInvalidProof.selector));
        nft.mintWithDiscount{value: priceWithDiscount}(proof, 0);
    }

    function test_MintEmitEvent() public {
        bytes32[] memory proof = m.getProof(discountData, 0);

        vm.prank(discounter1);
        vm.deal(discounter1, priceWithDiscount);
        vm.expectEmit(true, true, true, true, address(nft));
        emit DiscountClaimed(0, discounter1);

        nft.mintWithDiscount{value: priceWithDiscount}(proof, 0);
    }

    // Helpers

    function getDiscountData() internal view returns (bytes32[] memory data) {
        data = new bytes32[](discountTreeSize);

        for (uint160 i = 0; i < uint160(discountTreeSize); i++) {
            data[i] = keccak256(bytes.concat(keccak256(abi.encode(getDiscounterAddress(i), i))));
        }
    }

    function getDiscounterAddress(uint160 index) internal view returns (address) {
        return address(uint160(discounter1) + index);
    }
}
