/* Order of Layout
Contract elements should be laid out in the following order:

Pragma statements
Import statements
Events
Errors
Interfaces
Libraries
Contracts

Inside each contract, library or interface, use the following order:
Type declarations
State variables
Events
Errors
Modifiers
Functions */


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Janus Lottery contract
 * @author Harold Rosenberg
 * @notice This contract is for creating a Janus Lottery. The Janus Lottery has two sides: Jackpot funders and ticker buyers.
 * @notice First there is a Jackpot funding phase. In which funders compete for the best jackpot. 
 * @notice A jackpot offer has the total amount, the winning chance, ticket price and the selling period.
 * @notice Second phase is ticket buying.
 * @notice A ticket holder can win the jackpot. The funder can win the ticket sales if no one wins.
 * @notice The contractor owner gets a fee.  
 * @dev This implements the Chainlink VRF Version 2
 */

contract JanusLottery {

    /** Type declarations */

    /**
     JACKPOT_FUNDING is the initial state and the state in whice Jackpot Offers can be made
     by funder. After the funding phase the state transitions to TICKET_SELLING.
     TICKET_SELLING is the state in which tickets can be bought. After the selling period
     the state transitions to CALCULATION if at least one ticket was sold, otherwise to JACKPOT_FUNDING.
     In CALCULATION state a random number is request at Chainlink VRF and processed to pick a winner.
     After this the state transitions to JACKPOT_FUNDING.
     */
    enum JanusState {
        JACKPOT_FUNDING,
        TICKET_SELLING,
        CALCULATION
    }

    /**
     Winner holds the winner's address, price amount and wether it was a funder or not.
     */
    struct Winner {
        address winner;
        uint256 amount;
        bool funder;
    }


    /** State variables */
    uint256 private immutable i_minimum_jackpot;
    uint16 private immutable i_funding_period_hours;
    uint16 private immutable i_minimum_selling_period_hours;
    uint16 private immutable i_maximum_selling_period_hours;
    uint16 private immutable i_promille_fee;

    uint256 s_tickets_total_amount;    
    address payable[] private s_ticket_holders;
    Winner[] private s_winners;
    address payable s_funder;
    uint256 private s_jackpot;
    uint256 private s_jackpot_indicator;
    uint32 private s_maximum_tickets;
    uint16 private s_selling_period_hours;
    uint256 private s_ticket_price;
    JanusState private s_state;
    address public s_owner;

    /** Events */

    event TicketSaleOpened();
    event TicketSold(address indexed player, uint256 price);
    event JackPotOffered(address indexed funder, uint256 amount, uint ticketPrice, uint32 maximum_tickets, uint16 selling_period_hours);
    event TicketWon(address indexed player, uint256 price);
    event FunderWon(address indexed funder, uint256 price);

    /** Errors */
    error JanusLottery__NotInFundingState();
    error JanusLottery__TicketSellingPeriodTooLong();
    error JanusLottery__TicketSellingPeriodTooShort();
    error JanusLottery__MaximumTicketsTooSmall();
    error JanusLottery__JackpotTooSmall();
    error JanusLottery__OfferLost();
    error JanusLottery__SoldOut();
    error JanusLottery__EntranceFeeTooLow();
    error JanusLottery__OfferRejected();
    error JanusLottery__InvalidTicketPrice();
    error JanusLottery__JackpotMissing();
    error JanusLottery__NotSellingTickets();
    error JanusLottery__TransferFailed();
    error JanusLottery__NotPickingWinner();
    error JanusLottery__InvalidConstructionParameter();

    /** Modifiers **/

    // withJackpot modifier that validates only  
    // that contract has a jackpot offer
    modifier withJackpot() { 
        if (!hasJackpot()) {
            revert JanusLottery__JackpotMissing();
        }
        _;
    } 
    
    modifier fundingJackpot() {
        if (s_state != JanusState.JACKPOT_FUNDING) {
            revert JanusLottery__NotInFundingState();
        }
        _;
    }

    modifier sellingTickets() {
        if (s_state != JanusState.TICKET_SELLING) {
            revert JanusLottery__NotSellingTickets();
        }
        _;
    }

    modifier pickingWinners() {
        if (s_state != JanusState.CALCULATION) {
            revert JanusLottery__NotPickingWinner();
        }
        _;
    }


    /** Functions */

    constructor(uint16 minimum_selling_period_hours, 
                uint16 maximum_selling_period_hours, 
                uint16 funding_period_hours, 
                uint256 minimum_jackpot, 
                uint16 promille_fee) {

        if (minimum_selling_period_hours < 1 ||
            minimum_selling_period_hours > maximum_selling_period_hours ||
            funding_period_hours < 1 ||
            minimum_jackpot == 0 ||
            promille_fee > 999) {
            revert JanusLottery__InvalidConstructionParameter();
        }

        i_promille_fee = promille_fee;
        i_funding_period_hours = funding_period_hours;
        i_minimum_selling_period_hours = minimum_selling_period_hours;
        i_maximum_selling_period_hours = maximum_selling_period_hours;
        i_minimum_jackpot = minimum_jackpot;
        s_owner = msg.sender;
        s_state = JanusState.JACKPOT_FUNDING;
    }

    /** Payables */

    //fund the lottery
    function jackPotOffer(  uint256 ticketPrice, 
                            uint32 maximum_tickets, 
                            uint16 selling_period_hours) fundingJackpot public payable {

        if (ticketPrice==0) {
            revert JanusLottery.JanusLottery__InvalidTicketPrice();
        }

        if (selling_period_hours < i_minimum_selling_period_hours) {
            revert JanusLottery__TicketSellingPeriodTooShort();
        }

        if (selling_period_hours > i_maximum_selling_period_hours) {
            revert JanusLottery__TicketSellingPeriodTooLong();
        }

        if (maximum_tickets == 0) {
            revert JanusLottery__MaximumTicketsTooSmall();
        }

        if (msg.value < i_minimum_jackpot) {
            revert JanusLottery__JackpotTooSmall();
        }

        uint256 jackPotIndicator = msg.value / maximum_tickets;
        uint256 currentIndicator = s_jackpot_indicator;

        //Is there already an offer?
        //yes, then compare
        if (s_funder != address(0)) {
          
            if (jackPotIndicator < currentIndicator ||
                (jackPotIndicator == currentIndicator && 
                 s_selling_period_hours > selling_period_hours) ||
                (jackPotIndicator == currentIndicator && 
                 s_selling_period_hours == selling_period_hours && 
                 ticketPrice > s_ticket_price)) {
                
                //worse offer
                revert JanusLottery__OfferRejected();
            }
        }

        s_jackpot_indicator = jackPotIndicator;
        s_jackpot = msg.value;
        s_funder = payable(msg.sender);
        s_maximum_tickets = maximum_tickets;
        s_selling_period_hours = selling_period_hours;
        s_ticket_price = ticketPrice;

        emit JackPotOffered(msg.sender, msg.value, ticketPrice, maximum_tickets, selling_period_hours);

    }

    function buyTicket() sellingTickets public payable {
        
        if (msg.value != s_ticket_price) {
            revert JanusLottery__InvalidTicketPrice();
        }

        if (getTotalTicketHolders() >= s_maximum_tickets) {
            revert JanusLottery__SoldOut();
        }

        s_ticket_holders.push(payable(msg.sender));
        s_tickets_total_amount += msg.value; 

        emit TicketSold(msg.sender, msg.value);   	
    }


    function openTicketSales() fundingJackpot private {
        s_state = JanusState.TICKET_SELLING;
        emit TicketSaleOpened();
    }

    function closeTicketSales() sellingTickets private {

        if (getTotalTicketHolders()==0) {
            //no sales, return jackpot to funder
            address payable fund_receiver = s_funder;
            s_funder = payable(address(0));
            s_ticket_holders = new address payable[](0);
            s_state = JanusState.JACKPOT_FUNDING;

            (bool success,) = fund_receiver.call{value: s_jackpot}("");
            if (!success) {
                revert JanusLottery__TransferFailed();
            }

        }
        else
        {
            s_state = JanusState.CALCULATION;
            requestRandomWords();
        }
    }

    function requestRandomWords() private {

    }

    function pickWinner(uint256[] calldata randomWords) pickingWinners private {

        Winner memory winner;
        address payable funder = s_funder;
        uint256 funder_amount;

        address payable ticket_holder;
        uint256 ticket_amount;

        uint256 indexOfWinner = randomWords[0] % s_maximum_tickets;

        uint256 nonFeePromille = 1000-i_promille_fee;

        if (indexOfWinner < s_ticket_holders.length) {
            //ticket winner
            ticket_holder = s_ticket_holders[indexOfWinner];
            funder_amount = (nonFeePromille*s_tickets_total_amount)/1000;
            ticket_amount = (nonFeePromille*s_jackpot)/1000;
            winner = Winner(ticket_holder,ticket_amount,false);

        } else {
            //funder winner
            funder_amount = (nonFeePromille*(s_tickets_total_amount + s_jackpot))/1000;
            winner = Winner(funder,funder_amount,true);
        }

        uint256 fee_amount = (s_tickets_total_amount + s_jackpot) - (funder_amount + ticket_amount);

        s_funder = payable(address(0));
        s_ticket_holders = new address payable[](0);
        s_tickets_total_amount = 0;
        s_state = JanusState.JACKPOT_FUNDING;
        s_winners.push(winner);

        (bool successFunder,) = funder.call{value: funder_amount}("");
        if (!successFunder) {
            revert JanusLottery__TransferFailed();
        }

        if (ticket_amount > 0) {
            (bool successTicket,) = ticket_holder.call{value: ticket_amount}("");
            if (!successTicket) {
                revert JanusLottery__TransferFailed();
            }
        }

        if (fee_amount > 0) {
            (bool successFee,) = payable(s_owner).call{value: fee_amount}("");
            if (!successFee) {
                revert JanusLottery__TransferFailed();
            }
        }

        if (ticket_amount > 0) {
            emit TicketWon(ticket_holder,ticket_amount);
        }

        if (ticket_amount > 0) {
            emit FunderWon(funder,funder_amount);
        }

    }


    /** Getter functions */
    function hasJackpot() public view returns(bool) {
        return (s_funder != address(0));
    }

    function getFunder() withJackpot public view returns(address) {
        return s_funder;
    }

    function getJackpot() withJackpot public view returns(uint256) {
        return s_jackpot;
    }

    function getMaximumTickets() withJackpot public view returns(uint32) {
        return s_maximum_tickets;
    }

    function getSellingPeriodHours() withJackpot public view returns(uint16) {
        return s_selling_period_hours;
    }

    function getTicketPrice() withJackpot public view returns(uint256) {
        return s_ticket_price;
    }

    function getTotalWinners() public view returns(uint256) {
        return s_winners.length;
    }

    function getWinner(uint256 index) public view returns(Winner memory) {
        return s_winners[index];
    }

    function getTotalTicketHolders() public view returns(uint256) {
        return s_ticket_holders.length;
    }

    function getTicketHolder(uint256 index) public view returns(address) {
        return s_ticket_holders[index];
    }

    function getTotalTicketsSale() public view returns(uint256) {
        return s_tickets_total_amount;
    }

    function getOwner() public view returns(address) {
        return s_owner;
    }

    function getFeePromille() public view returns(uint16) {
        return i_promille_fee;
    }

    function getFundingPeriodHours() public view returns(uint16) {
        return i_funding_period_hours;
    }

    function getMinimumSellingPeriodHours() public view returns(uint16) {
        return i_minimum_selling_period_hours;
    }

    function getMaximumSellingPeriodHours() public view returns(uint16) {
        return i_maximum_selling_period_hours;
    }

    function getMinimumJackotPot() public view returns(uint256) {
        return i_minimum_jackpot;
    }

    function isFunding() public view returns(bool) {
        return s_state == JanusState.JACKPOT_FUNDING;
    }

    function isSelling() public view returns(bool) {
        return s_state == JanusState.TICKET_SELLING;
    }

    function isCalculating() public view returns(bool) {
        return s_state == JanusState.CALCULATION;
    }



}
