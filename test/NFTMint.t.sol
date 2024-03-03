// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";

contract NFTMintTest is Test {
    NFT public nft;

    address owner = address(1);
    address minter = address(2);
    uint256 price;

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        price = nft.PRICE();

        vm.deal(minter, 100_000 ether);
    }

    function test_MintOne() public {
        vm.prank(minter);
        nft.mint{value: price}();

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), minter);
        assertEq(address(nft).balance, price);
    }

    function test_MintAll() public {
        mintAll();

        assertGt(nft.MAX_TOTAL_SUPPLY(), 1);
        assertEq(nft.MAX_TOTAL_SUPPLY(), nft.totalSupply());
    }

    function test_MintMoreThenTotalSupply() public {
        mintAll();

        vm.expectRevert(abi.encodeWithSelector(NFT.NFTTotalSupplyReached.selector));
        nft.mint{value: price}();
    }

    function test_MintWithInvalidPrice() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.NFTPriceNotMatched.selector, price, price - 1));
        nft.mint{value: price - 1}();
    }

    // Helpers

    function mintAll() internal {
        vm.startPrank(minter);
        uint256 maxTotalSupply = nft.MAX_TOTAL_SUPPLY();

        for (uint256 i = 0; i < maxTotalSupply; i++) {
            nft.mint{value: price}();
        }
        vm.stopPrank();
    }
}
