
//HTML page environement variables
var game = document.getElementById('game');
var boxes = document.querySelectorAll('li');
var turnDisplay = document.getElementById('whos-turn');
var statusDisplay = document.getElementById('game-status');
var gameMessages = document.getElementById('game-messages');
var newGame = document.getElementById('new-game');
var joinGame = document.getElementById('join-game');
// var startGame;
var player;
var gameOver = false;
var accounts;
var betAmount;


if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    //this Dapp requires the use of metamask
    alert('please install metamask')
}
const eth = new Eth(web3.currentProvider);

var TicTacToeContract;
var TicTacToe;

//Play functions
var init = async function() {
    let response = await fetch('/artifacts/contracts/TicTacToe.sol/TicTacToe.json');
    const data = await response.json()
    const abi = data.abi
    const byteCode = data.bytecode

    accounts = await ethereum.request({ method: 'eth_requestAccounts' });

    TicTacToeContract = eth.contract(abi, byteCode, { from: accounts[0], gas: '3000000' });

    ethereum.on('accountsChanged', async function (accounts) {
        accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        TicTacToeContract = eth.contract(abi, byteCode, { from: accounts[0], gas: '3000000' });
    });
    
    //the user can first create or join a game
    newGame.addEventListener('click',newGameHandler,false);
    joinGame.addEventListener('click',joinGameHandler, false);
    
    //events listeners for user to click on the board
    for(var i = 0; i < 9; i++) {
        boxes[i].addEventListener('click', clickHandler, false);
    }
    renderInterval = setInterval(render, 1000);
    render();
}

var checkWin = function(){

    //checks the contract on the blockchain to verify if there is a winner or not
    if (typeof TicTacToe != 'undefined'){
        var win;
        TicTacToe.status().then(function(res){
            win = res[0].words[0];
            console.log(win)
            var displayResult;
            statusDisplay.innerHTML = "Status: " + win
            if (win>0 && win<4){
                if (win==3){
                    displayResult = "Draw ! game is over";
                } else if (win == 2){
                    displayResult = "Player 2 wins ! game is over";
                } else if (win == 1) {
                    displayResult = "Player 1 wins ! game is over";
                }
                gameOver = true;
                document.querySelector('#game-messages').innerHTML = displayResult;

                for (var i = 0; i < 9; i++){
                    boxes[i].removeEventListener('click', clickHandler);
                }

                return true;
            } else if (win == 0){
                document.querySelector('#game-messages').innerHTML = "Waiting for players...";
            } else if (win == 4) {
                document.querySelector('#game-messages').innerHTML = "Game in progress...";
            }
        });
    }
    return false;
}

var render = function(){

    //renders the board byt fetching the state of the board from the blockchain
    if (typeof TicTacToe != 'undefined'){
        TicTacToe.showBoard().then(function(res){
            for (var i = 0; i < 3; i++){
                for (var j = 0; j < 3; j++){
                    var state = res[0][i][j].words[0];
                    if (state>0){
                        var box_i = 3*i + j;
                        if (state==1){
                            boxes[box_i].className = 'x';
                            boxes[box_i].innerHTML = 'x';
                        } else{
                            boxes[box_i].className = 'o';
                            boxes[box_i].innerHTML = 'o';
                        }
                    }
                }   
            }
        });
        checkWin();
        if (!gameOver){
            turnMessageHandler();
        }
    }
}

var turnMessageHandler = function(){
    TicTacToe.turn().then(function(res){
        if (res[0].words[0] == player){
            turnDisplay.innerHTML = "Your turn !";
        } else {
            turnDisplay.innerHTML = "Not your turn !";
        }
    });
}

var newGameHandler = function(){

    //creates a new contract based on the user input of their opponent's address
    if (typeof TicTacToe != 'undefined'){
        console.log("There seems to be an existing game going on already");
    } else{
        var opponentAddress = document.getElementById('opponent-address').value
        betAmount = document.getElementById('bet-amount').value;

        console.log(opponentAddress)
        TicTacToeContract.new(opponentAddress, { from: accounts[0], gas: '3000000',  value: web3.utils.toWei(betAmount.toString(), "ether")})
        .then(function(txHash) {
            var waitForTransaction = setInterval(function(){
                eth.getTransactionReceipt(txHash, function(err, receipt){
                    if (receipt) {
                        clearInterval(waitForTransaction);
                        TicTacToe = TicTacToeContract.at(receipt.contractAddress);
                        //display the contract address to share with the opponent
                        
                        document.querySelector('#new-game-address').innerHTML = "BET AMOUNT OF " + betAmount + " PLACED <br><br>" 
                        + "Share the contract address with your opponnent: " + String(TicTacToe.address) + "<br><br>";
                        player = 1;

                        document.querySelector('#player').innerHTML = "Player 1";
                    }
                })
            }, 300);
        
        })
        
    }
}

var joinGameHandler = function(){
     //idem for joining a game
     var contractAddress = document.getElementById('contract-ID-tojoin').value.trim();
     TicTacToe = TicTacToeContract.at(contractAddress);
 
     TicTacToe.betAmount().then(function(res) {
         console.log(res)
         betAmount = web3.utils.fromWei(res[0].toString(), 'ether');
         if (betAmount == 0) {
             document.querySelector('#bet-amount-field-join').innerHTML = "Try Again..."
         } else {
             document.querySelector('#bet-amount-field-join').innerHTML = 
             "Bet Amount of " + betAmount + " requried to join game. <button class=\"buttons\" id=\"start-game\" onclick=\"joinGameConfirmHandler()\">Confirm</button> <br><br>"
         }
         
     });
}

var joinGameConfirmHandler = function(){
    TicTacToe.join({ from: accounts[0], gas: '3000000',  value: web3.utils.toWei(betAmount.toString(), "ether")}).then(function(res) {
        player = 2;
        document.querySelector('#player').innerHTML = "Player " + player;
        document.querySelector('#bet-amount-field-join').innerHTML = "Game of " + betAmount + " ETH stakes joined."
    });
    
}

var clickHandler = function() {

    //called when the user clicks a cell on the board

    if (typeof TicTacToe != 'undefined'){
        if (checkWin()){
            return;
        }
        var target_x = this.getAttribute('data-pos-x');
        var target_y = this.getAttribute('data-pos-y');
        TicTacToe.validMove(target_x, target_y).then(function(res){
            if (res[0]) {
                TicTacToe.turn().then(function(res) {
                    if (res[0].words[0] == player) {
                        TicTacToe.move(target_x, target_y).catch(function(err){
                            console.log('something went wrong ' + String(err));
                        }).then(function(res){
                            this.removeEventListener('click', clickHandler);
                            render();
                        });
                    }
                });
            }
        });
    }
}

init();
