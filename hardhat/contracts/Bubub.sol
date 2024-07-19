// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bubub is ERC20, Ownable {
    uint256 private immutable _maxSupply;

    /**
     * @dev Constructor to initialize the Bubub token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param maxSupply_ The maximum supply of the token
     */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) 
        ERC20(name_, symbol_)
        Ownable()
    {
        require(maxSupply_ > 0, "Max supply must be greater than zero");
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Mint new tokens
     * @notice Only the contract owner can mint new tokens
     * @param to The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= _maxSupply, "Exceeds maximum supply");
        _mint(to, amount);
    }

    /**
     * @dev Returns the maximum supply of tokens
     * @return The maximum supply of tokens
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
}