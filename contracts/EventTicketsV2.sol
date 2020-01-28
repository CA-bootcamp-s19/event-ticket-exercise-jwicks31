pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint TICKET_PRICE = 100 wei;
    uint currentEventId;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Buyer {
        address payable buyer;
        uint totalTickets;
        bool isBuyer;
    }

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping(address => Buyer) buyers;
    }

    mapping(uint => Event) events;
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier verifyCaller(address _address) { require(_address == owner); _;}
    modifier verifyBuyer(uint _id, address _address) { require(events[_id].buyers[_address].isBuyer); _; }
    modifier checkIsOpen(bool _isOpen) {
        require(_isOpen == true);
        _;
    }

    modifier checkTicketCount(uint _totalTickets, uint _numTickets) { require(_numTickets <= _totalTickets); _;}

    modifier checkValue(uint _price, uint _numTickets) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint totalValue = _price * _numTickets;
        uint amountToRefund = msg.value - totalValue;
        msg.sender.transfer(amountToRefund);
    }

    constructor() public {
        owner = msg.sender;
        currentEventId = 0;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory url, uint numTickets) public verifyCaller(msg.sender) {
        emit LogEventAdded(description, url, numTickets, currentEventId);
        events[currentEventId].description = description;
        events[currentEventId].website = url;
        events[currentEventId].totalTickets = numTickets;
        events[currentEventId].sales = 0;
        events[currentEventId].isOpen = true;
        currentEventId++;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */

    function readEvent(uint id) public view returns(string memory description, string memory url, uint totalTickets, uint sales, bool isOpen) {
        return(events[id].description, events[id].website, events[id].totalTickets, events[id].sales, events[id].isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
       function buyTickets(uint id, uint numTickets)
        public payable checkIsOpen(events[id].isOpen) checkTicketCount(events[id].totalTickets, numTickets) checkValue(TICKET_PRICE, numTickets) returns(bool) {
        emit LogBuyTickets(msg.sender, id, numTickets);
        events[id].buyers[msg.sender].totalTickets += numTickets;
        events[id].buyers[msg.sender].buyer = msg.sender;
        events[id].buyers[msg.sender].isBuyer = true;
        events[id].totalTickets -= numTickets;
        events[id].sales += numTickets;
        return true;
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint id) public verifyBuyer(id, msg.sender) returns(bool) {
        emit LogGetRefund(msg.sender, id, events[id].buyers[msg.sender].totalTickets);
        events[id].buyers[msg.sender].isBuyer = false;
        events[id].totalTickets += events[id].buyers[msg.sender].totalTickets;
        events[id].sales -= events[id].buyers[msg.sender].totalTickets;
        events[id].buyers[msg.sender].buyer.transfer(TICKET_PRICE * events[id].buyers[msg.sender].totalTickets);
        events[id].buyers[msg.sender].totalTickets = 0;
        return true;
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint id) public view returns(uint numberOfTickets) {
        return events[id].buyers[msg.sender].totalTickets;
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint id) public verifyCaller(msg.sender) returns(bool) {
        emit LogEndSale(msg.sender, events[id].sales * TICKET_PRICE, id);
        events[id].isOpen = false;
        msg.sender.transfer(TICKET_PRICE * events[id].sales);
    }
}
