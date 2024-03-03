// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken public rewardToken;

    address owner = address(1);
    address minter = address(2);
    address stranger = address(3);

    function setUp() public {
        rewardToken = new RewardToken("Reward Token", "TKN", owner);
    }

    // Initial state

    function test_Name() public {
        assertEq(rewardToken.name(), "Reward Token");
    }

    function test_Symbol() public {
        assertEq(rewardToken.symbol(), "TKN");
    }

    function test_Minter() public {
        assertEq(rewardToken.minter(), address(0));
    }

    function test_TotalSupply() public {
        assertEq(rewardToken.totalSupply(), 0);
    }

    // Set minter

    function test_SetMinter() public {
        vm.prank(owner);
        rewardToken.setMinter(minter);
        assertEq(rewardToken.minter(), minter);
    }

    function test_SetMinterFromStranger() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        rewardToken.setMinter(stranger);
    }

    // Mint

    function test_Mint() public {
        vm.prank(owner);
        rewardToken.setMinter(minter);

        address to = address(2);
        uint256 amount = 100;

        vm.prank(minter);
        rewardToken.mint(to, amount);

        assertEq(rewardToken.balanceOf(to), amount);
    }

    function test_MintFromStranger() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(RewardToken.OnlyMinter.selector));
        rewardToken.mint(stranger, 100);
    }
}
