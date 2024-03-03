// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RewardToken
 * @dev This contract represents a reward token that can be minted by staking contract
 */
contract RewardToken is ERC20, Ownable2Step {
    address public minter;

    error OnlyMinter();

    /**
     * @dev Constructor function
     * @param name The name of the reward token
     * @param symbol The symbol of the reward token
     * @param owner The address of the contract owner
     */
    constructor(string memory name, string memory symbol, address owner) ERC20(name, symbol) Ownable(owner) {}

    /**
     * @dev Mint new reward tokens
     * @param to The address to which the reward tokens will be minted
     * @param amount The amount of reward tokens to mint
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    /**
     * @dev Sets the address of the minter
     * @param newMinter The address of the minter
     * @notice Only the contract owner can call this function
     */
    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    /**
     * @dev Modifier to restrict function execution to the staking contract
     */
    modifier onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }
}
