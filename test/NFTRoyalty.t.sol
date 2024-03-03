// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {NFT} from "../src/NFT.sol";

contract NFTRoyaltyTest is Test {
    NFT public nft;

    address owner = address(1);

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
    }

    // https://eips.ethereum.org/EIPS/eip-2981#checking-if-the-nft-being-sold-on-your-marketplace-implemented-royalties
    function test_SupportsRoyalties() public {
        bytes4 INTERFACE_ID_ERC2981 = 0x2a55205a;
        (bool success) = IERC165(address(nft)).supportsInterface(INTERFACE_ID_ERC2981);
        assertTrue(success);
    }

    function test_RoyaltyInfo() public {
        uint256 salePrice = 1 ether;
        (address royaltyReceiver, uint256 royaltyAmount) = nft.royaltyInfo(0, salePrice);

        assertEq(royaltyReceiver, owner);
        assertEq(royaltyAmount, salePrice * 250 / 10000); // 2.5%
    }
}
