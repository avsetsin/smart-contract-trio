// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NFT} from "../src/NFT.sol";

contract NFTWithdrawTest is Test {
    NFT public nft;

    address owner = address(1000);
    address stranger = address(2000);

    function setUp() public {
        nft = new NFT("NFT token", "NFT", owner, bytes32(0));
    }

    function test_InitialState() public {
        assertEq(nft.balanceOf(address(nft)), 0);
    }

    function test_Withdraw() public {
        uint256 amount = 10 ether;
        uint256 ownerBalanceBefore = address(owner).balance;

        vm.deal(address(nft), amount);
        vm.prank(owner);
        nft.withdrawETH();
        uint256 ownerBalanceAfter = address(owner).balance;

        assertEq(nft.balanceOf(address(nft)), 0);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + amount);
    }

    function test_WithdrawFromStranger() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        nft.withdrawETH();
    }
}
