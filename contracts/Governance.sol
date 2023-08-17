//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Interfaces/IRewardToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    struct User {
        uint256 availableCoins;
        uint256 purchaseCoins;
        uint256 refferalCoins;
        uint256 reviewCoins;
        uint256 reedemedCoins;
        mapping(address brands => uint256 coins) rewardCoins;
    }

    struct UserRewardData {
        uint256 timestamp;
        uint256 amount;
    }

    struct Brand {
        uint256 totalCoinsPool;
        uint256 usedForServices;
        mapping(address user => UserRewardData[]) userRewardData;
    }

    address private immutable i_tokenAddress;
    uint256 private purchaseRewardRate = 100;
    uint256 private refferalCoinsRewarded = 200;
    uint256 private reviewRewardRate = 50;
    uint256 private maxCoinsPossible = 1000;

    mapping(address user => User obj) addressToUser;
    mapping(address brand => Brand obj) addressToBrand;

    error MORE_THAN_MAX_POSSIBLE_COINS();
    error REFFERED_USER_ITSELF();
    error AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error NOT_SUFFICIENT_COINS_TO_REDEEM();
    error ZERO_ADDRESS_NOT_ALLOWED();
    error NOT_SUFFICIENT_COINS_TO_SEND();
    error NOT_SUFFICIENT_COINS_TO_BURN();

    event Tokens_Burned(uint256 amount);
    event Brand_Reward_Burned(uint256 amount);
    event Tokens_Expired();
    event Token_Rewarded(
        address indexed brand,
        address indexed user,
        uint256 indexed amount
    );

    event Purchase_Coins_Received(
        address indexed user,
        address indexed brand,
        uint256 indexed coins
    );

    event Refferal_Coins_Received(
        address indexed personRefferedBy,
        address indexed personReffered,
        uint256 indexed coins
    );

    event Review_Award_Transferred();

    modifier sameUser(address _userAddress) {
        if (msg.sender == _userAddress) {
            revert REFFERED_USER_ITSELF();
        }
        _;
    }

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }
        _;
    }

    modifier greaterThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        _;
    }

    constructor(address _tokenAddress) {
        i_tokenAddress = _tokenAddress;
    }

    function purchaseItem(
        uint256 _purchaseAmount,
        address _brandAddress
    ) external {
        uint256 coins = _purchaseAmount * purchaseRewardRate;
        if (coins > maxCoinsPossible) {
            coins = maxCoinsPossible;
        }
        //Mint for user as well as brands
        User storage _user = addressToUser[msg.sender];
        _user.purchaseCoins += coins;
        _user.availableCoins += coins;
        Brand storage brand = addressToBrand[_brandAddress];
        brand.totalCoinsPool += coins;
        IRewardToken(i_tokenAddress).mint(coins, msg.sender);
        IRewardToken(i_tokenAddress).mint(coins, _brandAddress);
        emit Purchase_Coins_Received(msg.sender, _brandAddress, coins);
    }

    function refferalUser(
        address reffererAddress
    ) external sameUser(reffererAddress) {
        //Update all the mappings
        User storage _user1 = addressToUser[reffererAddress];
        User storage _user2 = addressToUser[msg.sender];
        _user1.refferalCoins += refferalCoinsRewarded;
        _user1.availableCoins += refferalCoinsRewarded;
        _user2.refferalCoins += refferalCoinsRewarded;
        _user2.availableCoins += refferalCoinsRewarded;
        IRewardToken(i_tokenAddress).mint(
            refferalCoinsRewarded,
            reffererAddress
        );
        IRewardToken(i_tokenAddress).mint(refferalCoinsRewarded, msg.sender);
        // then mint for the user as well as refree
        emit Refferal_Coins_Received(
            reffererAddress,
            msg.sender,
            refferalCoinsRewarded
        );
    }

    function reviewItem(
        uint256 _amount,
        address _userToPay
    ) external onlyOwner greaterThanZero(_amount) {
        // update the mappings and only owner can pay to the user , will only and update thew mappings
        User storage _user = addressToUser[_userToPay];
        _user.reviewCoins += _amount;
        _user.availableCoins += _amount;
        IRewardToken(i_tokenAddress).mint(_amount, _userToPay);
        emit Review_Award_Transferred();
    }

    // redeem coins on purchase , review and refferal

    function redeemCoins(
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) {
        // User mapping would be updated and then that much tokens would be burned from user balance
        User storage _user = addressToUser[msg.sender];
        uint256 _availableCoins = _user.availableCoins;
        if (_availableCoins < _coinsAmount) {
            revert NOT_SUFFICIENT_COINS_TO_REDEEM();
        }
        _user.availableCoins -= _coinsAmount;
        _user.reedemedCoins += _coinsAmount;
        IRewardToken(i_tokenAddress).burn(_coinsAmount, msg.sender);
        emit Tokens_Burned(_coinsAmount);
    }

    function redeemBrandReward(
        address _brandAddress,
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) {
        // Brand mapping would be updated and then that much tokens would be burned from user balance
        User storage _user = addressToUser[msg.sender];
        uint256 brandCoins = _user.rewardCoins[_brandAddress];
        if (brandCoins < _coinsAmount) {
            revert NOT_SUFFICIENT_COINS_TO_REDEEM();
        }
        _user.rewardCoins[_brandAddress] -= _coinsAmount;
        _user.reedemedCoins += _coinsAmount;
        IRewardToken(i_tokenAddress).burn(_coinsAmount, msg.sender);
        emit Brand_Reward_Burned(_coinsAmount);
    }

    function rewardUser(
        address _rewardingUser,
        uint256 _amount
    ) external greaterThanZero(_amount) {
        // The Brand will give tokens to their loyal users on their own
        // We will update the rewards mapping in the users table as well as the rewards mapping in the brands struct
        // We will also update the totalRewardedCoins in the brands struct
        Brand storage _brand = addressToBrand[msg.sender];
        User storage _user = addressToUser[_rewardingUser];
        if (_brand.totalCoinsPool < _amount) {
            revert NOT_SUFFICIENT_COINS_TO_SEND();
        }
        _brand.totalCoinsPool -= _amount;
        _brand.userRewardData[_rewardingUser].push(
            UserRewardData(block.timestamp, _amount)
        );
        _user.rewardCoins[msg.sender] += _amount;

        /*Approve first in frontend using approve then call this */
        IRewardToken(i_tokenAddress).transferFrom(msg.sender,_rewardingUser, _amount);
        emit Token_Rewarded(msg.sender, _rewardingUser, _amount);
    }

    function expireTokens(uint256 _amount) external greaterThanZero(_amount) {
        User storage _user = addressToUser[msg.sender];
        if (_user.availableCoins < _amount) {
            revert NOT_SUFFICIENT_COINS_TO_BURN();
        }
        _user.availableCoins -= _amount;
        IRewardToken(i_tokenAddress).burn(_amount, msg.sender);
        emit Tokens_Expired();
    }
}
