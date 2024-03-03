// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingSetupTest is Test {
    NFT public nft;
    RewardToken public rewardToken;
    Staking public staking;

    address owner = address(1);
    uint256 rewardsPerDay;

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        rewardToken = new RewardToken("Reward Token", "TKN", owner);

        rewardsPerDay = 10 * 10 ** rewardToken.decimals();
        staking = new Staking(address(rewardToken), address(nft), rewardsPerDay, owner);

        vm.prank(owner);
        rewardToken.setMinter(address(staking));
    }

    function test_RewardToken() public {
        assertEq(address(staking.REWARD_TOKEN()), address(rewardToken));
    }

    function test_NFT() public {
        assertEq(address(staking.STAKED_TOKEN()), address(nft));
    }

    function test_RewardsPerDay() public {
        assertGt(rewardsPerDay, 0);
        assertEq(staking.REWARDS_PER_DAY(), rewardsPerDay);
    }

    function test_Owner() public {
        assertEq(staking.owner(), owner);
    }
}
