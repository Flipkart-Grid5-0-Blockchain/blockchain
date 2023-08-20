//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RewardToken - A custom ERC20 token with a max supply limit
/// @author HackBots

contract RewardToken is ERC20, Ownable {
    uint256 private maxSupply = 10 ** 10 * 10 ** 18;

    error TREASURY_EXHAUSTED();

    /*-------Modifiers---------- */

    /// @dev Modifier to check if adding `_amount` to the total supply exceeds the `maxSupply`.
    modifier supplyExhausted(uint256 _amount) {
        if (totalSupply() + _amount > maxSupply) {
            revert TREASURY_EXHAUSTED();
        }
        _;
    }

    /// @dev Constructor to initialize the RewardToken contract.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    /*-----External Functions------- */
    /// @notice Mint new tokens and add them to `_user`'s balance.
    /// @param _amount The amount of tokens to mint.
    /// @param _user The address to which the minted tokens will be added.
    /// @return `true` if minting is successful.

    function mint(
        uint256 _amount,
        address _user
    ) external supplyExhausted(_amount) onlyOwner returns (bool) {
        _mint(_user, _amount);
        return true;
    }

    /// @notice Burn a specified amount of tokens from `_user`'s balance.
    /// @param amount The amount of tokens to burn.
    /// @param _user The address from which tokens will be burned.

    function burn(uint256 amount, address _user) external onlyOwner {
        _burn(_user, amount);
    }

    /// @notice Update the maximum supply of the token.
    /// @param _newSupply The new maximum supply.
    function updateSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    /// @notice Change the owner of the contract to `_newOwner`.
    /// @param _newOwner The address of the new owner.
    function changeOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }

    /// @notice Get the maximum supply of the token.
    /// @return The maximum supply.
    function getSupply() external view onlyOwner returns (uint256) {
        return maxSupply;
    }
}
