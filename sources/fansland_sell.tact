import "@stdlib/ownable";
import "@stdlib/deploy";

const ERROR_COIN_NOT_SUPPORT: Int = 1;  //The pay coin does not match

contract FanslandContract with Deployable,Ownable{
    
    event_flag: Bool = true;
    pay_coin_map: map<Address,Int>;
    nft_collection_map: map<Address,Int>;
    score_coin_address: Address;
  
    owner : Address;
    total_supply: Int as uint32 = 0;
    current_mint_count: Int as uint32 = 0;

    mint_score: Int as coins =0;
    recommend_score: Int as coins =0;

    trans_score_flag: Bool = true; //flag:transfer score coin
    back_pay_coin_flag: Bool = true; //flag:funds pay coin

    get fun getEventFlag(): Bool {
        return self.event_flag;
    }
    get fun getCollectionMap(): map<Address,Int> {
        return self.nft_collection_map;
    }
    get fun getPayCoinMap(): map<Address,Int> {
        return self.pay_coin_map;
    }

    get fun getTotalSupply(): Int {
        return self.total_supply;
    }
    get fun getCurrentMintCount(): Int {
        return self.current_mint_count;
    }
    get fun getMintScore(): Int {
        return self.mint_score;
    }
    get fun getRecommendScore(): Int {
        return self.recommend_score;
    }

    init(_total_supply: Int,_score_coin_address: Address ){
        self.total_supply = _total_supply;
        self.score_coin_address = _score_coin_address;
        self.owner = context().sender;
    }

    receive(msg: ResetFlag) {
        self.requireOwner();
        self.event_flag = msg.event_flag;
        self.trans_score_flag = msg.trans_score_flag;
        self.back_pay_coin_flag = msg.back_pay_coin_flag;
    }

    receive(msg: UpdateProcess){
        self.requireOwner();
        self.total_supply=msg.total_supply;
        self.current_mint_count=msg.current_mint_count;
    }
    receive(msg: AddPayCoin){
        self.requireOwner();
        self.pay_coin_map.set(msg.pay_coin_address,msg.pay_coin_symbol);
    }
    receive(msg: SubPayCoin){
        self.requireOwner();
        self.pay_coin_map.set(msg.pay_coin_address,null);
    }
    receive(msg: UpdateScore){
        self.requireOwner();
        self.score_coin_address=msg.score_coin_address;
        self.mint_score=msg.mint_score;
        self.recommend_score=msg.recommend_score;
    }


    receive(msg: AddTicketType) {
        self.requireOwner();
        require(msg.price>0, "price too lower");
        self.nft_collection_map.set(msg.col_addr,msg.price);
    }

    receive(msg: TokenNotification) {
        // require(msg.amount>0, "send amount not enough");
        // if (self.pay_coin_map.get(context().sender) == null || self.pay_coin_map.get(context().sender) == 0){
        //     //The pay coin does not match
        //     throw(ERROR_COIN_NOT_SUPPORT);
        // }

        // if(!self.event_flag){
        //      //event close
        //     self.transferPayCoin(context().sender,msg.from,msg.amount);
        //     return;
        // }
        // if(self.total_supply-self.current_mint_count<=0){
        //     //balance not enough ,funds
        //     self.transferPayCoin(context().sender,msg.from,msg.amount);
        //     return;
        // }

        let payload: Slice = msg.forward_payload;
        let parent_addr: Address = payload.loadAddress();
        let ticket_addr: Address = payload.loadAddress();
        let buy_count: Int = payload.loadUint(16);
        // if(buy_count<=0){
        //       //buy count error
        //     self.transferPayCoin(context().sender,msg.from,msg.amount);
        //     return;
        // }
        // let nft_price: Int? = self.nft_collection_map.get(ticket_addr);
        // if(nft_price==null ||nft_price==0){
        //     //not found ticket,funds
        //     self.transferPayCoin(context().sender,msg.from,msg.amount);
        //     return;
        // }
        // self.current_mint_count = self.current_mint_count +buy_count;
        // self.transferScoreCoin(msg.from,self.mint_score*buy_count); // first reward
      
        // if(parent_addr!=myAddress()){
        //     // parent reward
        //     self.transferScoreCoin(parent_addr,self.recommend_score*buy_count);
        // }
        // //mint nft
        // self.mintNftByCount(ticket_addr,msg.from,buy_count);
        emit(FanslandMint{mint_address: msg.from,mint_nft_collection: ticket_addr, mint_count: buy_count}.toCell());
    }


    fun mintNftByCount(_nft_addr: Address,_to_addr: Address,_rec_count: Int){
        send(SendParameters{
                to: _nft_addr,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: MintCount{
                    to: _to_addr,
                    rec_count: _rec_count
                }.toCell()
            }
        );
    }

    fun transferPayCoin(_coin_address: Address,_toAddr: Address,_amount: Int){
         if (self.back_pay_coin_flag){
            send(SendParameters{
                to: _coin_address,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    amount: _amount,
                    destination: _toAddr,
                    response_destination: myAddress(),
                    custom_payload: null,
                    forward_ton_amount: ton("0.01"),
                    forward_payload: emptySlice()
                }.toCell()
            }
            );
        }
        
    }

    fun transferScoreCoin(_toAddr: Address,_amount: Int){
        if (self.trans_score_flag){
            send(SendParameters{
                to: self.score_coin_address,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: true,
                body: TokenTransfer{
                    query_id: 0,
                    amount: _amount,
                    destination: _toAddr,
                    response_destination: myAddress(),
                    custom_payload: null,
                    forward_ton_amount: ton("0.01"),
                    forward_payload: emptySlice()
                }.toCell()
            }
            );
        }
        
    }
    

}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}
message AddTicketType {
    col_addr: Address;
    price: Int as coins;
}

message ResetFlag {
    event_flag: Bool;
    trans_score_flag: Bool;
    back_pay_coin_flag: Bool;
}

message UpdateProcess {
    total_supply: Int as uint32;
    current_mint_count: Int as uint32;
}

message UpdatePayCoin {
    pay_coin_address: Address;
    pay_coin_symbol: Int as uint32;
}

message UpdateScore {
    score_coin_address: Address;
    mint_score: Int as coins;
    recommend_score: Int as coins;
}
message MintCount {
    to: Address;
    rec_count: Int as uint32;
}
message FanslandMint {
    mint_address: Address;
    mint_nft_collection: Address;
    mint_count: Int;
}
message AddPayCoin {
    pay_coin_address: Address;
    pay_coin_symbol: Int;
}

message SubPayCoin {
    pay_coin_address: Address;
}


message EmitMsg {
    addr: Address;
    mm: String;
}