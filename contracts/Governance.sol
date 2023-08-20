// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/// @title Governance Smart Contract
/// @author Hackathon Team

import "./Interfaces/IRewardToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {

    //Type Declarations
    /// @dev Struct to represent a user's data.
    struct User {
        uint256 availableCoins;
        uint256 purchaseCoins;
        uint256 refferalCoins;
        uint256 reviewCoins;
        uint256 reedemedCoins;
        mapping(address brands => uint256 coins) rewardCoins;
    }

    /// @dev Struct to represent a user's reward data.
    struct UserRewardData {
        uint256 timestamp;
        uint256 amount;
    }

    /// @dev Struct to represent a brand's data.
    struct Brand {
        uint256 totalCoinsPool;
        mapping(address user => UserRewardData[]) userRewardData;
    }

    // Immutable variable for the token address.
    address private immutable i_tokenAddress;

    // Reward rates and limits.
    uint256 public purchaseRewardRate = 100;
    uint256 public refferalCoinsRewarded = 200;
    // uint256 public reviewRewardRate = 50;
    uint256 public maxCoinsPossible = 1000;

    // Reward rates and limits.
    mapping(address => User) public addressToUser;
    mapping(address => Brand) public addressToBrand;
    mapping(address => bool) private registeredAddress;
    mapping(address => string) private registeredUsers;

    // Errors
    error MORE_THAN_MAX_POSSIBLE_COINS();
    error REFFERED_USER_ITSELF();
    error AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error NOT_SUFFICIENT_COINS_TO_REDEEM();
    error ZERO_ADDRESS_NOT_ALLOWED();
    error NOT_SUFFICIENT_COINS_TO_SEND();
    error NOT_SUFFICIENT_COINS_TO_BURN();
    error USER_IS_NOT_REGISTERED();
    error ADDRESS_IS_NOT_REGISTERED();

    // Events

    /// @dev Emitted when tokens are burned.
    /// @param amount The amount of tokens burned.
    event Tokens_Burned(uint256 amount);

    /// @dev Emitted when brand reward tokens are burned.
    /// @param amount The amount of brand reward tokens burned.
    event Brand_Reward_Burned(uint256 amount);

     /// @dev Emitted when tokens expire.
    event Tokens_Expired();

    /// @dev Emitted when tokens are rewarded to a user by a brand.
    /// @param brand The address of the brand rewarding the tokens.
    /// @param user The address of the user receiving the tokens.
    /// @param amount The amount of tokens rewarded.
    event Token_Rewarded(
        address indexed brand,
        address indexed user,
        uint256 indexed amount
    );

    /// @dev Emitted when purchase coins are received by a user from a brand.
    /// @param user The address of the user.
    /// @param brand The address of the brand.
    /// @param coins The amount of purchase coins received.
    event Purchase_Coins_Received(
        address indexed user,
        address indexed brand,
        uint256 indexed coins
    );

    /// @dev Emitted when referral coins are received by a referred user from a referrer.
    /// @param personRefferedBy The address of the person who referred.
    /// @param personReffered The address of the person being referred.
    /// @param coins The amount of referral coins received.
    event Refferal_Coins_Received(
        address indexed personRefferedBy,
        address indexed personReffered,
        uint256 indexed coins
    );

    /// @dev Emitted when a review award is transferred to a user.
    event Review_Award_Transferred();

    // Modifiers

    /// @dev Modifier to ensure that the user is not referring themselves.
    modifier sameUser(address _userAddress) {
        if (msg.sender == _userAddress) {
            revert REFFERED_USER_ITSELF();
        }
        _;
    }

    /// @dev Modifier to ensure that an address is not the zero address.
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }
        _;
    }

     /// @dev Modifier to ensure that a value is greater than zero.
    modifier greaterThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        _;
    }

    /// @dev Modifier to ensure that a user is registered.
    modifier isUserRegistered() {
        if (bytes(registeredUsers[msg.sender]).length == 0) {
            revert USER_IS_NOT_REGISTERED();
        }
        _;
    }

    /// @dev Modifier to ensure that a brand address is registered.
    modifier isBrandAddressRegistered() {
        if (registeredAddress[msg.sender] == false) {
            revert ADDRESS_IS_NOT_REGISTERED();
        }
        _;
    }

    //Functions

    /// @dev Constructor to initialize the token address.
    constructor(address _tokenAddress) {
        i_tokenAddress = _tokenAddress;
    }

    /// @dev Registers a user with their email address.
    /// @param _email The email address of the user.
    function registerUser(string memory _email) external {
        registeredUsers[msg.sender] = _email;
    }

    /// @dev Registers an address as a brand.
    function registerAddress() external {
        registeredAddress[msg.sender] = true;
    }

    /// @dev Allows users to purchase items from a brand and earn reward coins.
    /// @param _purchaseAmount The purchase amount.
    /// @param _brandAddress The address of the brand.
    function purchaseItem(
        uint256 _purchaseAmount,
        address _brandAddress
    ) external isUserRegistered {
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

    /// @dev Refers a new user and rewards both the referrer and the referred user.
    /// @param reffererAddress The address of the referrer.

    function refferalUser(
        address reffererAddress
    ) external sameUser(reffererAddress) isUserRegistered {
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

    /// @dev Awards coins to a user for reviewing an item.
    /// @param _amount The amount of coins to award.
    /// @param _userToPay The user to award the coins to.
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

    /* Add a modfier for the brand check*/

    /// @dev Redeems coins earned through purchases, referrals, or rewards.
    /// @param _coinsAmount The amount of coins to redeem.
    function redeemCoins(
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) isUserRegistered {
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

    /// @dev Redeems brand reward coins earned by the user.
    /// @param _brandAddress The address of the brand.
    /// @param _coinsAmount The amount of coins to redeem.
    function redeemBrandReward(
        address _brandAddress,
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) isUserRegistered {
        //Check the available coins* that in the user mapping
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

    /// @dev Rewards a user with tokens from a brand's reward pool.
    /// @param _rewardingUser The user rewarding the tokens.
    /// @param _amount The amount of tokens to reward.
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
        /*Approve function to be added so that user can call and not on */
        IRewardToken(i_tokenAddress).transferFrom(
            msg.sender,
            _rewardingUser,
            _amount
        );
        emit Token_Rewarded(msg.sender, _rewardingUser, _amount);
    }

    /// @dev Expires unused tokens, both from brand coins and platform coins.
    /// @param _brandCoins The amount of brand coins to expire.
    /// @param _brands An array of brand addresses.
    /// @param _brandAmount An array of brand coin amounts.
    /// @param _platformCoins The amount of platform coins to expire.
    function expireTokens(
        uint256 _brandCoins,
        address[] memory _brands,
        uint256[] memory _brandAmount,
        uint256 _platformCoins
    ) external {
        User storage _user = addressToUser[msg.sender];
        /*check for array lengths to be same */
        if (_brandCoins > 0) {
            for (uint i = 0; i < _brands.length; i++) {
                /*Addd validation checks for that no zero address is there */
                if (_user.rewardCoins[_brands[i]] < _brandAmount[i]) {
                    revert NOT_SUFFICIENT_COINS_TO_BURN();
                }
                _user.rewardCoins[_brands[i]] -= _brandAmount[i];
            }
        }
        if (_platformCoins > 0) {
            if (_user.availableCoins < _platformCoins) {
                revert NOT_SUFFICIENT_COINS_TO_BURN();
            }
            _user.availableCoins -= _platformCoins;
        }
        IRewardToken(i_tokenAddress).burn(
            _brandCoins + _platformCoins,
            msg.sender
        );
        emit Tokens_Expired();
    }

    /// @dev Updates the reward rate for purchases.
    /// @param _updatedRate The new reward rate.
    function updatePurchaseReward(uint256 _updatedRate) external onlyOwner {
        purchaseRewardRate = _updatedRate;
    }

    /// @dev Updates the reward amount for referrals.
    /// @param _updatedReward The new reward amount.
    function updateRefferalReward(uint256 _updatedReward) external onlyOwner {
        refferalCoinsRewarded = _updatedReward;
    }

    /// @dev Updates the maximum possible coins.
    /// @param _updatedReward The new maximum possible coins.
    function updateMaxCoins(uint256 _updatedReward) external onlyOwner {
        maxCoinsPossible = _updatedReward;
    }

    /*All getter functions 
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


    mapping(address user => User obj) public addressToUser;
    mapping(address brand => Brand obj) public addressToBrand;
    mapping(address => bool) private registeredAddress;
    mapping(address => bool) private registeredUsers;
    */

    /// @dev Retrieves the brand coins earned by a user for a specific brand.
    /// @param user The user's address.
    /// @param brand The brand's address.
    /// @return The amount of brand coins.
    function getUserBrandCoins(
        address user,
        address brand
    ) external view returns (uint256) {
        User storage _user = addressToUser[user];
        return _user.rewardCoins[brand];
    }

    /// @dev Retrieves the reward data for a specific user from a specific brand.
    /// @param brand The brand's address.
    /// @param user The user's address.
    /// @return An array of UserRewardData structs representing the reward data.
    function getBrandRewardData(
        address brand,
        address user
    ) external view returns (UserRewardData[] memory) {
        Brand storage _brand = addressToBrand[brand];
        return _brand.userRewardData[user];
    }

    /// @dev Retrieves the address of the token used in the contract.
    /// @return The token address.
    function getTokenAddress() external view onlyOwner returns (address) {
        return i_tokenAddress;
    }

    // * receive function
    receive() external payable {}

    // * fallback function
    fallback() external payable {}
}
