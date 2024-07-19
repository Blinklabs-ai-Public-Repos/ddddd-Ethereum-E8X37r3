// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bubub is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private immutable _maxSupply;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 cliff;
    }

    mapping(address => VestingSchedule) private _vestingSchedules;

    event VestingScheduleCreated(address indexed beneficiary, uint256 totalAmount, uint256 startTime, uint256 duration, uint256 cliff);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @dev Constructor to initialize the Bubub token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param maxSupply_ The maximum supply of the token
     */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) 
        ERC20(name_, symbol_)
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
        require(totalSupply().add(amount) <= _maxSupply, "Exceeds maximum supply");
        _mint(to, amount);
    }

    /**
     * @dev Returns the maximum supply of tokens
     * @return The maximum supply of tokens
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Creates a new vesting schedule for a beneficiary
     * @param beneficiary Address of the beneficiary to whom vested tokens are transferred
     * @param totalAmount Total amount of tokens to be released at the end of the vesting
     * @param startTime The time (as Unix time) at which point vesting starts
     * @param duration Duration in seconds of the period in which the tokens will vest
     * @param cliff Duration in seconds of the cliff in which tokens will begin to vest
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration,
        uint256 cliff
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary can't be zero address");
        require(totalAmount > 0, "Total amount must be > 0");
        require(duration > 0, "Duration must be > 0");
        require(cliff <= duration, "Cliff must be <= duration");
        require(_vestingSchedules[beneficiary].totalAmount == 0, "Vesting schedule already exists");

        uint256 cliffTime = startTime.add(cliff);
        _vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: startTime,
            duration: duration,
            cliff: cliffTime
        });

        emit VestingScheduleCreated(beneficiary, totalAmount, startTime, duration, cliff);

        _mint(address(this), totalAmount);
    }

    /**
     * @dev Release vested tokens to beneficiary
     * @param beneficiary Address of the beneficiary to whom vested tokens are transferred
     */
    function release(address beneficiary) external {
        VestingSchedule storage schedule = _vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule for this address");

        uint256 releasable = _vestedAmount(beneficiary).sub(schedule.releasedAmount);
        require(releasable > 0, "No tokens are due for release");

        schedule.releasedAmount = schedule.releasedAmount.add(releasable);
        _transfer(address(this), beneficiary, releasable);

        emit TokensReleased(beneficiary, releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested for a given beneficiary
     * @param beneficiary Address of the beneficiary to check
     * @return The amount of tokens already vested
     */
    function _vestedAmount(address beneficiary) private view returns (uint256) {
        VestingSchedule memory schedule = _vestingSchedules[beneficiary];
        if (block.timestamp < schedule.cliff) {
            return 0;
        } else if (block.timestamp >= schedule.startTime.add(schedule.duration)) {
            return schedule.totalAmount;
        } else {
            return schedule.totalAmount.mul(block.timestamp.sub(schedule.startTime)).div(schedule.duration);
        }
    }

    /**
     * @dev Returns the vesting schedule information for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return The vesting schedule information
     */
    function getVestingSchedule(address beneficiary) external view returns (VestingSchedule memory) {
        return _vestingSchedules[beneficiary];
    }
}