//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    /*
     * State
     * Events
     * Modifier
     * Functions
     **/
    uint256 private maxSupply = 10 ** 8 * 10 ** 18;

    error TREASURY_EXHAUSTED();

    /*-------Modifiers---------- */
    modifier supplyExhausted(uint256 _amount) {
        if (totalSupply() + _amount > maxSupply) {
            revert TREASURY_EXHAUSTED();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    /*-----External Functions------- */
    function mint(
        uint256 _amount,
        address _user
    ) external supplyExhausted(_amount) onlyOwner returns (bool) {
        _mint(_user, _amount);
        return true;
    }

    function burn(uint256 amount, address _user) external onlyOwner {
        _burn(_user, amount);
    }

    function updateSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }

    function getSupply() external view onlyOwner returns (uint256) {
        return maxSupply;
    }
}

/*-------Public Functions--------- */

/*-------Internal Functions-------- */

/*-------Private Functions---------- */
