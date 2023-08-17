//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardToken is IERC20 {
    function mint(uint256 _amount, address _user) external returns (bool);

    function burn(uint256 amount, address _user) external;

    function updateSupply(uint256 _newSupply) external;
}
