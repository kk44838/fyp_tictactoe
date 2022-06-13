//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.19;

/**
 * @title TicTacToe contract
 **/
contract TicTacToe {
    uint constant GAME_NOT_STARTED = 0;
    uint constant GAME_PLAYER_1_WON = 1;
    uint constant GAME_PLAYER_2_WON = 2;
    uint constant GAME_DRAW = 3;
    uint constant GAME_STARTED = 4;

    address[2] public players;
    uint8 public playersJoined;
    
    /**
      Amount to bet
     */
    uint256 public betAmount;

    /**
     turn
     1 - players[0]'s turn
     2 - players[1]'s turn
     */
    uint public turn = 1;


    /**
     status
     0 - Not started
     1 - players[0] won
     2 - players[1] won
     3 - draw
     4- ongoing
     */
    uint public status = GAME_NOT_STARTED;
    bool private paidWinner = false;
    /**
    board status
     0    1    2
     3    4    5
     6    7    8
     */
    uint[3][3] private board;

    /**
      * @dev Deploy the contract to create a new game
      * @param opponent The address of player2
      **/
    constructor(address opponent) public payable {
        require(msg.sender != opponent, "No self play.");
        require(msg.value > 0, "Bet too small");

        betAmount = msg.value;
        players[0] = msg.sender;
        players[1] = opponent;
        playersJoined = 1;
    }


    function join() external payable  {
        require (playersJoined == 1, "Already joined");
        require(msg.sender == players[1], "You are not the opponent");
        require(msg.value == betAmount, "Wrong bet amount.");

        playersJoined = 2;
        status = GAME_STARTED;
    }


    /**
      * @dev Check a, b, c in a line are the same
      * _threeInALine doesn't check if a, b, c are in a line
      * @param a position a
      * @param b position b
      * @param c position c
      */    
    function _threeInALine(uint a, uint b, uint c) private pure returns (bool){
       
        return (a != 0 && a == b && a == c);

    }

    function winnerInRow(uint[3][3] memory _board) private pure returns (uint){
      for (uint8 x = 0; x < 3; x++) {
        if (_threeInALine(_board[x][0], _board[x][1], _board[x][2])) {
          return _board[x][0];
        }
      }

      return GAME_STARTED;
    }

    function winnerInColumn(uint[3][3] memory _board) private pure returns (uint){
      for (uint8 y = 0; y < 3; y++) {
        if (_threeInALine(_board[0][y], _board[1][y], _board[2][y])) {
          return _board[0][y];
        }
      }

      return GAME_STARTED;
    }

    function winnerInDiagonal(uint[3][3] memory _board) private pure returns (uint){
      
      if (_threeInALine(_board[0][0], _board[1][1], _board[2][2])) {
        return _board[0][0];
      }
      
      if (_threeInALine(_board[0][2], _board[1][1], _board[2][0])) {
        return _board[0][0];
      }

      return GAME_STARTED;
    }

    function fullBoard(uint[3][3] memory _board) private pure returns (bool){
      
      for (uint j=0; j < _board.length; j++) {
        for (uint k=0; k < _board.length; k++) {
          if (_board[j][k] == 0) {
            return false;
          }
        }
      }

      return true;
    }



    /**
     * @dev get the status of the game
     * @return the status of the game
     */
    function _getStatus() private view returns (uint) {
       

        uint cur_status = winnerInRow(board);

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        cur_status = winnerInColumn(board);

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        cur_status = winnerInDiagonal(board);

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        if (fullBoard(board)) {
          return GAME_DRAW;
        }

        return GAME_STARTED;
    }

    /**
     * @dev ensure the game is still ongoing before a player moving
     * update the status of the game after a player moving
     */
    modifier _checkStatus {
       
        require(status == GAME_STARTED, "Game is Complete.");
        _;
        status = _getStatus();
        if (status > GAME_NOT_STARTED && status < GAME_DRAW) {
          payWinner();
        } else if (status == GAME_DRAW) {
          draw();
        }
    }

    /**
     * @dev check if it's msg.sender's turn
     * @return true if it's msg.sender's turn otherwise false
     */
    function myTurn() public view returns (bool) {
      
       return msg.sender == players[turn-1];
    }

    /**
     * @dev ensure it's a msg.sender's turn
     * update the turn after a move
     */
    modifier _myTurn() {
      require(myTurn(), "Not your turn!");
      _;
      turn = (turn % 2) + 1;

    }

    /**
     * @dev check a move is valid
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     * @return true if valid otherwise false
     */
    function validMove(uint pos_x, uint pos_y) public view returns (bool) {
      return pos_x >= 0 && pos_x < 9 && pos_y >= 0 && pos_y < 9 && board[pos_x][pos_y] == 0;

    }

    /**
     * @dev ensure a move is valid
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     */
    modifier _validMove(uint pos_x, uint pos_y) {
      require (validMove(pos_x, pos_y), "Move is invalid.");
      _;
    }

    /**
     * @dev a player makes a move
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     */
    function move(uint pos_x, uint pos_y) public _validMove(pos_x, pos_y) _checkStatus _myTurn {
        board[pos_x][pos_y] = turn;
    }

    /**
     * @dev show the current board
     * @return board
     */
    function showBoard() public view returns (uint[3][3]) {
      return board;
    }

    function draw() private {
      if (!paidWinner) {
        paidWinner = true;
        players[0].transfer(betAmount);
        players[1].transfer(betAmount);
      } 
    }

    function payWinner() private {
      if (!paidWinner) {
        paidWinner = true;
        players[status - 1].transfer(betAmount + betAmount);
      }
    }
}

