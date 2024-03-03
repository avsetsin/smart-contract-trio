// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingRewardsTest is Test {
    NFT public nft;
    RewardToken public rewardToken;
    Staking public staking;

    address owner = address(1);
    address staker = address(2);
    address stranger = address(3);
    uint256 rewardsPerDay;

    event RewardsClaimed(address indexed account, uint256 indexed tokenId, uint256 amount);

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        rewardToken = new RewardToken("Reward Token", "TKN", owner);

        rewardsPerDay = 10 * 10 ** rewardToken.decimals();
        staking = new Staking(address(rewardToken), address(nft), rewardsPerDay, owner);

        vm.prank(owner);
        rewardToken.setMinter(address(staking));
    }

    function test_RewardsAfterStaking() public {
        uint256 tokenId = mintNFTAndStake(staker);

        uint256 rewards = staking.claimableRewards(tokenId);
        assertEq(rewards, 0);
    }

    function test_RewardsAfter1Day() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.warp(block.timestamp + 1 days);
        uint256 rewards = staking.claimableRewards(tokenId);
        assertEq(rewards, rewardsPerDay);
    }

    function test_RewardsAfter10Days() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.warp(block.timestamp + 10 days);
        uint256 rewards = staking.claimableRewards(tokenId);
        assertEq(rewards, rewardsPerDay * 10);
    }

    function test_RewardsForNotStakedToken() public {
        uint256 notStakedTokenId = 999;
        vm.expectRevert(abi.encodeWithSelector(Staking.TokenIsNotStaked.selector, notStakedTokenId));
        staking.claimableRewards(notStakedTokenId);
    }

    // Claim

    function test_ClaimRewards() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.warp(block.timestamp + 1 days);

        uint256 balanceBefore = rewardToken.balanceOf(staker);

        vm.prank(staker);
        staking.claimRewards(tokenId);
        uint256 balanceAfter = rewardToken.balanceOf(staker);

        assertGt(rewardsPerDay, 0);
        assertEq(balanceAfter - balanceBefore, rewardsPerDay);
    }

    function test_ClaimAfterStaking() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.prank(staker);
        staking.claimRewards(tokenId);
        uint256 balance = rewardToken.balanceOf(staker);

        assertEq(balance, 0);
    }

    function test_NoClaimableRewardsAfterClaim() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.warp(block.timestamp + 1 days);
        vm.prank(staker);
        staking.claimRewards(tokenId);

        uint256 rewards = staking.claimableRewards(tokenId);
        assertEq(rewards, 0);
    }

    function test_ClaimRewardsByStranger() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Staking.NotTokenOwner.selector, staker, stranger));
        staking.claimRewards(tokenId);
    }

    // Events

    function test_ClaimEmitEvent() public {
        uint256 tokenId = mintNFTAndStake(staker);
        vm.warp(block.timestamp + 1 days);

        vm.prank(staker);
        vm.expectEmit(true, true, true, true, address(staking));
        emit RewardsClaimed(staker, tokenId, rewardsPerDay);

        staking.claimRewards(tokenId);
    }

    function test_ClaimEmitEventFor0Rewards() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.prank(staker);
        vm.expectEmit(true, true, true, true, address(staking));
        emit RewardsClaimed(staker, tokenId, 0);

        staking.claimRewards(tokenId);
    }

    // Withdraw should claim rewards

    function test_WithdrawShouldClaimRewards() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.warp(block.timestamp + 1 days);

        uint256 balanceBefore = rewardToken.balanceOf(staker);
        vm.prank(staker);
        staking.withdraw(tokenId);
        uint256 balanceAfter = rewardToken.balanceOf(staker);

        assertEq(balanceAfter - balanceBefore, rewardsPerDay);
    }

    function test_WithdrawWihoutRewards() public {
        uint256 tokenId = mintNFTAndStake(staker);

        vm.prank(staker);
        staking.withdraw(tokenId);
        uint256 balance = rewardToken.balanceOf(staker);

        assertEq(balance, 0);
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
