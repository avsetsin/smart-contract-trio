// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingRecoverTest is Test {
    NFT public nft;
    RewardToken public rewardToken;
    Staking public staking;

    address owner = address(1);
    address staker = address(2);
    uint256 rewardsPerDay;

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        rewardToken = new RewardToken("Reward Token", "TKN", owner);

        rewardsPerDay = 10 * 10 ** rewardToken.decimals();
        staking = new Staking(address(rewardToken), address(nft), rewardsPerDay, owner);

        vm.prank(owner);
        rewardToken.setMinter(address(staking));
    }

    function test_RecoverNonStakedNFT() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        nft.transferFrom(staker, address(staking), tokenId);

        assertFalse(staking.isStaked(tokenId));
        assertEq(nft.ownerOf(tokenId), address(staking));

        vm.prank(owner);
        staking.recoverNFT(tokenId, staker);

        assertFalse(staking.isStaked(tokenId));
        assertEq(nft.ownerOf(tokenId), staker);
    }

    function test_RecoverDoesntWorkForStakedNFT() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        nft.safeTransferFrom(staker, address(staking), tokenId);

        assertTrue(staking.isStaked(tokenId));
        assertEq(staking.ownerOf(tokenId), staker);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Staking.TokenIsStaked.selector, tokenId));
        staking.recoverNFT(tokenId, staker);
    }

    // Helpers

    function mintNFT(address from) internal returns (uint256 tokenId) {
        uint256 price = nft.PRICE();
        vm.prank(from);
        vm.deal(from, price);
        tokenId = nft.mint{value: price}();
    }
}
