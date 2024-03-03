// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingWithdrawTest is Test {
    NFT public nft;
    RewardToken public rewardToken;
    Staking public staking;

    address owner = address(1);
    address staker = address(2);
    address stranger = address(3);
    uint256 rewardsPerDay;

    event Withdrawn(address indexed account, uint256 indexed tokenId);

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        rewardToken = new RewardToken("Reward Token", "TKN", owner);

        rewardsPerDay = 10 * 10 ** rewardToken.decimals();
        staking = new Staking(address(rewardToken), address(nft), rewardsPerDay, owner);

        vm.prank(owner);
        rewardToken.setMinter(address(staking));
    }

    function test_WithdrawStaked() public {
        uint256 tokenId = mintNFTAndStake(staker);
        vm.warp(block.timestamp + 1 days);

        vm.prank(staker);
        staking.withdraw(tokenId);
    }

    function test_WithdrawStakedByStranger() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Staking.NotTokenOwner.selector, staker, stranger));
        staking.withdraw(tokenId);
    }

    function test_WithdrawNotStaked() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        vm.expectRevert(abi.encodeWithSelector(Staking.TokenIsNotStaked.selector, tokenId));
        staking.withdraw(tokenId);
    }

    function test_WithdrawEmitEvent() public {
        uint256 tokenId = mintNFTAndStake(staker);
        vm.warp(block.timestamp + 1 days);

        vm.prank(staker);
        vm.expectEmit(true, true, true, true, address(staking));
        emit Withdrawn(staker, tokenId);
        staking.withdraw(tokenId);
    }

    // Helpers

    function mintNFTAndStake(address from) internal returns (uint256 tokenId) {
        tokenId = mintNFT(from);
        vm.prank(from);
        nft.safeTransferFrom(from, address(staking), tokenId);
        assertStaked(tokenId, from);
    }

    function mintNFT(address from) internal returns (uint256 tokenId) {
        uint256 price = nft.PRICE();
        vm.prank(from);
        vm.deal(from, price);
        tokenId = nft.mint{value: price}();
    }

    function assertStaked(uint256 tokenId, address tokenOwner) internal {
        assertTrue(staking.isStaked(tokenId));
        assertEq(staking.ownerOf(tokenId), tokenOwner);
        assertEq(nft.ownerOf(tokenId), address(staking));
    }
}
