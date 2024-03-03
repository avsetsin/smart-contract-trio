// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, stdError, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/Staking.sol";

contract StakingStakeTest is Test {
    NFT public nft;
    RewardToken public rewardToken;
    Staking public staking;

    address owner = address(1);
    address staker = address(2);
    address stranger = address(3);
    uint256 rewardsPerDay;

    event Staked(address indexed account, uint256 indexed tokenId);

    function setUp() public {
        nft = new NFT("NFT", "NFT", owner, bytes32(0));
        rewardToken = new RewardToken("Reward Token", "TKN", owner);

        rewardsPerDay = 10 * 10 ** rewardToken.decimals();
        staking = new Staking(address(rewardToken), address(nft), rewardsPerDay, owner);

        vm.prank(owner);
        rewardToken.setMinter(address(staking));
    }

    function test_StakeWithApprove() public {
        uint256 tokenId = mintNFT(staker);

        vm.startPrank(staker);
        nft.approve(address(staking), tokenId);
        staking.stake(tokenId);
        vm.stopPrank();

        assertStaked(tokenId, staker);
    }

    function test_StakeWithApproveAll() public {
        uint256 tokenId = mintNFT(staker);

        vm.startPrank(staker);
        nft.setApprovalForAll(address(staking), true);
        staking.stake(tokenId);
        vm.stopPrank();

        assertStaked(tokenId, staker);
    }

    function test_StakeWithSafeTransfer() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        nft.safeTransferFrom(staker, address(staking), tokenId);

        assertStaked(tokenId, staker);
    }

    function test_StakeEmitEvents() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        vm.expectEmit(true, true, true, true, address(staking));
        emit Staked(staker, tokenId);

        nft.safeTransferFrom(staker, address(staking), tokenId);
    }

    // isStaked

    function test_IsStaked() public {
        uint256 tokenId = mintNFT(staker);
        vm.prank(staker);
        nft.safeTransferFrom(staker, address(staking), tokenId);
        assertTrue(staking.isStaked(tokenId));
    }

    function test_IsNotStaked() public {
        uint256 tokenId = mintNFT(staker);
        assertFalse(staking.isStaked(tokenId));
    }

    // onERC721Received

    function test_OnERC721ReceivedCallByNonNftAddress() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodePacked(Staking.InvalidCaller.selector));
        staking.onERC721Received(address(0), staker, 0, "");
    }

    function test_OnERC721ReceivedCallForStakedNFT() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(staker);
        nft.safeTransferFrom(staker, address(staking), tokenId);
        assertStaked(tokenId, staker);

        vm.prank(address(nft));
        vm.expectRevert(stdError.assertionError);
        staking.onERC721Received(address(0), staker, tokenId, "");
    }

    function test_OnERC721ReceivedCallNotTransferedNFT() public {
        uint256 tokenId = mintNFT(staker);

        vm.prank(address(nft));
        vm.expectRevert(stdError.assertionError);
        staking.onERC721Received(address(0), staker, tokenId, "");
    }

    // Helpers

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
