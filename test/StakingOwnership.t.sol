// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingOwnershipTest is Test {
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

    function test_OwnerOfStakedNFT() public {
        uint256 tokenId = mintNFTAndStake(staker);

        assertEq(staking.ownerOf(tokenId), staker);
    }

    function test_OwnerOfNotStakedNFT() public {
        uint256 notStakedTokenId = 999;
        vm.expectRevert(abi.encodePacked(Staking.TokenIsNotStaked.selector, notStakedTokenId));
        staking.ownerOf(notStakedTokenId);
    }

    // Helpers

    function mintNFTAndStake(address from) internal returns (uint256 tokenId) {
        tokenId = mintNFT(from);
        vm.prank(from);
        nft.safeTransferFrom(from, address(staking), tokenId);
    }

    function mintNFT(address from) internal returns (uint256 tokenId) {
        uint256 price = nft.PRICE();
        vm.prank(from);
        vm.deal(from, price);
        tokenId = nft.mint{value: price}();
    }
}
