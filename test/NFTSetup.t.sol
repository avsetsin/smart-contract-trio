// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";

contract NFTSetupTest is Test {
    NFT public nft;

    address owner = address(1);

    function setUp() public {
        nft = new NFT("NFT token", "NFT", owner, 0x0000000000000000000000000000000000000000000000000000000000000001);
    }

    function test_Name() public {
        assertEq(nft.name(), "NFT token");
    }

    function test_Symbol() public {
        assertEq(nft.symbol(), "NFT");
    }

    function test_Owner() public {
        assertEq(nft.owner(), owner);
    }

    function test_Price() public {
        assertEq(nft.PRICE(), 0.2 ether);
    }

    function test_PriceWithDiscount() public {
        assertEq(nft.PRICE_WITH_DISCOUNT(), 0.1 ether);
    }

    function test_MaxTotalSupply() public {
        assertEq(nft.MAX_TOTAL_SUPPLY(), 1000);
    }

    function test_DiscountTreeRoot() public {
        assertEq(nft.DISCOUNT_TREE_ROOT(), 0x0000000000000000000000000000000000000000000000000000000000000001);
    }

    function test_TotalSupply() public {
        assertEq(nft.totalSupply(), 0);
    }
}
